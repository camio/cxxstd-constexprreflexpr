% constexpr reflexpr

- Document number: **P???R1**, ISO/IEC JTC1 SC22 WG21
- Date: 2017-01-10
- Authors: Matúš Chochlík <chochlik@gmail.com>, Axel Naumann <axel@cern.ch>,
  and David Sankel <dsankel@bloomberg.net>
- Audience: SG7 Reflection

## Abstract

The reflexpr series of papers ([P0385](http://wg21.link/p0385),
[P0194](http://wg21.link/p0194), [P0578](http://wg21.link/p0578), and most
recently [P0670](http://wg21.link/p0670)) provide facilities for static
reflection that are based on the template metaprogramming paradigm. Recently,
however, language features have been proposed that would enable a more
natural syntax for metaprogramming through use of `constexpr` facilities
(See: [P0598](http://wg21.link/p0598), [P0633](http://wg21.link/p0633),
[P0712](http://wg21.link/p0712), and [P0784](http://wg21.link/p0784)). This
paper explores the impact of these language facilities on reflexpr and
considers what a natural-syntax-based reflection library would look like.

## Introduction

Template-metaprogramming-based reflexpr (TMP-reflexpr), which is succinctly
described in [P0578](http://wg21.link/p0578),  includes a `reflexpr` operator
that, when applied to C++ syntax, produces a *type* that encodes "meta"
information about that syntax. For example, when `reflexpr` is applied to a
type, the result can be used to query that type's name and, in the case of a
class, list its member variables.

Consider the following implementation of a function `dump` which outputs the
name and public data members of an arbitrary type. Note that iteration of the
data members involves use of an auxiliary function and variadic templates.

```c++
template <typename T>
void dumpDataMembers();

template <typename T>
void dump()
    // Output the name and data members of a record (class, struct, union).
    // For example:
    //..
    // struct S {
    //     std::string m_s;
    //     int m_i;
    // };
    // 
    // int main {
    //     dump<S>(); // outputs:
    //                // name: S
    //                // members:
    //                //   std::string m_s
    //                //   int m_i
    // }
    //..

{
    using MetaT = reflexpr(T);
    std::cout << "name: " << get_display_name_v<MetaT> << std::endl;
    std::cout << "members:" << std::endl;

    using DataMemberObjectSequence = get_public_data_members_t<MetaT>;
    dumpDataMembers<unpack_sequence<std::tuple, DataMemberObjectSequence>>();
}

template <>
void dumpDataMembers<std::tuple<>>() { }

template <typename DataMember, typename... DataMembers>
void dumpDataMembers<std::tuple<DataMember, DataMembers...>>() {
    std::cout
        << "\t" << get_display_name_v<get_type_t<DataMember>>
        << " " << get_display_name_v<DataMember>
        << std::endl;
    dumpDataMembers<std::tuple<DataMembers...>>();
}
```

While the above code could be simplified somewhat by use of a template
metaprogramming library such as Boost.MPL, this snippet is fairly
representative of the complexity and, for most software developers,
unfamiliarity of the required constructs.

Louis Dionne's Boost.Hana library provides an alternative approach whereby
values with specially designed types allow one to write code that has much of
the appearance of normal C++ code, but actually accomplishes metaprogramming
(See [P0425](http://wg21.link/p0425)).  Instead of having to write a separate
function to accomplish iteration, one could use the `hana::for_each` from
within the `dump` function.

```
hana::for_each(metaT.get_public_data_members(), [&](auto dataMember) {
    std::cout
        << "\t" << dataMember.getType().get_display_name()
        << " " << dataMember.get_display_name()
        << std::endl;
});
```

While this mitigates much of the syntactic complexity of template
metaprogramming, the types involved are opaque in that they cannot be named and
we still need special library features to accomplish tasks such as iteration.

Constexpr-based reflexpr (CXP-reflexpr), the subject of this paper, operates in
the Hana-style in that instead of `reflexpr` producing a *type*, it produces
a *value* that encodes meta information. Unlike Hana-style, however, this value
has a non-opaque type and we normally do not need special library features to
work with it.

The following snippet illustrates our original example using CXP-reflexper.

```c++
template <typename T>
void dump() {
    constexpr refl::Type t = reflexpr(T);
    std::cout << "name: " << t.get_display_name() << std::endl;
    std::cout << "members:" << std::endl;
    for(RecordMember member : t.get_public_data_members())
        std::cout
            << "\t" << member.get_type().get_display_name()
            << " " << member.get_name() << std::endl;
}
```

## Mixed compile/runtime

In the introductory example, we didn't have a need to mix a runtime value with
compile-time meta-information. While this is doable with TMP-reflexpr,
additional language facilities are required to accomplish this with
CXP-reflexpr.

Consider this example where we write a function `dumpJson` that outputs an
arbitrary `class` or `struct` in a JSON string. Note that we're using two new
language constructs `for...` and `unreflexpr`.

```c++
void dumpJson(std::string s);
    // Output 's' with double-quotes and escaped special characters.

template <typename T>
void dumpJson(T t) {
    std::cout << "{ ";
    constexpr refl::Type t = reflexpr(T);
    bool saw_prev = false;
    for...(RecordMember member : t.get_public_data_members())
    {
        if(saw_prev) {
            std::cout << ", ";
        }

        constexpr refl::Pointer pointerToMember = member.get_pointer();
        std::cout
            << member.get_name()
            << "=" << t.*unreflexpr(pointerToMember);

        saw_prev = true;
    }
    std::cout << "}" << std::endl;
}

struct S {
    std::string m_s;
    int m_i;
};

int main {
    dumpJson( S{"hello", 33 } ); // outputs: { m_s="hello", m_i=33 }
}
```

### `for...`

This construct essentially unrolls a for loop at compile-time, allowing for the
body of the loop to manifest different types at different iterations. This was
originally proposed by Andrew Sutton in [P0589](http://wg21.link/p0589) for
Hana-style programming, but the unrolling semantics work for our purposes as
well.

While this language construct isn't strictly necessary for CXP-reflexper, we
think it greatly simplifies code that would otherwise require complex library
facilities.

### constexpr-time allocators

constexpr-time allocators as described in [P0784](http://wg21.link/p0784) (also
seen in a more preliminary form in [P0597](http://wg21.link/p0784)) allow us to
make use of `std::vector`, among other data types, at compile time. While these
constructs aren't strictly necessary as resizable arrays based on fixed buffer
sizes has been demonstrated, they make the data structures used at compile time
more uniform with those at runtime.

### `unreflexpr`

With TMP-reflexpr, types are easily extracted because we are already in a type
context.

```
// 'foo' has a type that is the same as the first field of 'S'.
get_reflected_type_t<
  get_type_t<
    get_element_t<
        0,
        get_public_data_members_t<reflexpr(S)>>>> foo;
```

With CXP-reflexpr, on the other hand, once we have a 'Type' object, there isn't
a language facility for going back into type processing

```
constexpr Type t = reflexpr(S).get_public_data_members()[0].get_type();

// unreflexpr required to create 'foo' with the type that 't' refers to.
unreflexpr(t) foo;
```

Therefore, the one language-level feature that is critical for feature parity
with TMP-reflexpr is `unreflexpr` support. It is required for both types and
pointers to members.

## Library considerations

### Typeful reflection

Some of the initial sketches for constexpr-based reflection had the `reflexpr`
operation produce values that are always of the same type. While this has some
advantages to implementers and is certainly simpler that each value having its
own unique type, we feel that making some use of types will encourage
programming that is easier to read and reason about.

TODO: build a stronger argument here

### Incorporating functionality already in standard library

The C++ standard library at the time of this writing includes several
metafunctions that aid in metaprogramming. `std::add_const_t` is one such
example. While they can certainly be used in the CXP-reflexpr paradigm, it is
awkward:

```
Type p = /*...*/;
Type constP = reflexpr(std::add_const_t<unreflexpr(P)>);
```

We propose that each of these existing metaprogramming functions get a
CXP-reflexpr-styled equivalent with a new `_r` suffix.

```
namespace std {
  refl::Type add_const_r(const refl::Type t) {
    return reflexpr(std::add_const_t<unreflexpr(P)>);
  }
}
```

### Sketch of data types and operations

Note, this part up until the "Amalgamation type" section is a placeholder.

```
class Object {
    std::source_location get_source_location() const;
    int get_source_line() const;
    int get_source_column() const;
    std::string get_source_file_name() const;
};
``` 

```
class Named {
    bool is_anonymous() const;
    std::string get_name() const;
    std::string get_display_name() const;
};
```

```
class Type : public Object, public Named
{
public:
    bool is_enum() const;
    bool is_class() const;
    bool is_struct() const;
    bool is_union() const;
}
```

TODO: figure this out.

`reflexpr( texp )` where `texp` is some type expression. Possible results:

#### Amalgamation type

With this option `reflexpr( texp )` will always return a single type that has
members sufficient to handle all types. The resulting type will, for example,
have a `get_public_data_members` member function even if the argument to
`reflexpr` is an `enum` type.

#### Reference (class hierarchy)

With this option, `reflexpr` will return a pointer, instead of a value, that is
part of a class hierarchy

```c++
class Type
{
    // All types have names
    std::string get_name() const;
    std::string get_display_name() const;

    //...
};

class RecordType : public Type
{
    // Only record types (like class and union) may have public data members
    std::vector<RecordMember*> get_public_data_members()
};
```

For example:

```c++
struct S {};

// Note that both these statements work
RecordType *rt = reflexpr(S);
Type *t = reflexpr(S);
```

TODO: If we want to avoid downcasting, we'd want our object hierarchy to
include things such as 'RecordTypeAlias' and such.

#### Variant

One way to get value semantics instead of reference semantics is to use
`std::variant` or some compile-time equivalent.

```c++
using Type = std::variant<RecordType, EnumType, PrimitiveType, TypeAlias>
```

This implies that members such as `get_public_data_members` will not be
immediately available upon reflection. Instead helper functions would likely be
provided.

```c++
std::vector<RecordMember> get_public_data_members(Type t)
    // The behavior is undefined unless 't' is a 'RecordType' or a 'TypeAlias'
    // to a 'RecordType'.
{
    return std::visit(t,
        std::overload( // assuming P0051
            [](const RecordType & record) {
                return record.get_public_data_members();
            },
            [](const TypeAlias & alias) {
                return get_public_data_members(alias.get_aliased());
            },
            [](const auto &) {
                throw std::runtime_error("Not a type with data members");
            },
        ));
}
```

#### Variant-like classes

Another alternative is to use variant-like classes to achieve value semantics.
These are custom classes that provide member functions that can be used to
narrow down to more specific classes.

```c++
class Type {
public:
    bool is_record();
    bool is_enum();
    bool is_primitive();
    bool is_alias();

    RecordType to_record();
        // The behavior is undefined unless 'is_record() == true'
    EnumType to_enum();
        // The behavior is undefined unless 'is_enum() == true'
    PrimitiveType to_primitive();
        // The behavior is undefined unless 'is_primitive() == true'
    AliasType to_alias();
        // The behavior is undefined unless 'is_alias() == true'
};
```

This works much like the `variant` solution except that it avoids the more
complicated visitation syntax for most use cases.

```c++
std::vector<RecordMember> get_public_data_members(Type t)
    // The behavior is undefined unless 't' is a 'RecordType' or a 'TypeAlias'
    // to a 'RecordType'.
{
    if(t.is_record())
        return t.to_record().get_public_data_members();
    else if(t.is_alias() && t.to_alias().get_aliased().is_record())
        return t.to.alias().get_aliased().to_record().get_public_data_members();
    else
        throw std::runtime_error("Not a type with data members");
}
```

## Open Questions

Once we answer these questions, we can start filling in the API sketch.

- Do we prefer amalgamation, class hierarchies, variants, or variant-like
  objects?
- If we go with variant and variant-like objects, should we mix in class
  hierarchies where it makes sense? For example, an 'Object' base class? The
  alternative is use of concepts.
- Are we ready to send this to Daveed and Louis for feedback?

## Conclusion

TODO:
