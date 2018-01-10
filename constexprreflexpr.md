% constexpr reflexpr

- Document number: **P???R1**, ISO/IEC JTC1 SC22 WG21
- Date: 2017-01-10
- Authors: Matúš Chochlík <chochlik@gmail.com>, Axel Naumann <axel@cern.ch>,
  and David Sankel <dsankel@bloomberg.net>
- Audience: SG7 Reflection

## Abstract

The reflexpr series of papers ([P0385](http://wg21.link/p0385),
[P0194](http://wg21.link/p0194), [P0478](http://wg21.link/p0578), and most
recently [P0670](http://wg21.link/p0670)) provide facilities for static
reflection that are based on a template metaprogramming paradigm. Recently,
however, language features have been proposed that would enable a more
natural syntax for metaprogramming through use of `constexpr` facilities
(See: [P0425](http://wg21.link/p0425), [P0712](http://wg21.link/p0712), and
[P0784](http://wg21.link/p0784)). This paper explores the impact of
these langauge facilities on reflexpr and considers what a
natural-syntax-based reflection library would look like.

## Introduction

- TODO: introduce TMP-reflexpr and CXP-reflexpr

Compile time

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

struct S {
    std::string m_s;
    int m_i;
};

int main {
    dump<S>(); // outputs:
               // name: S
               // members:
               //   std::string m_s
               //   int m_i
}
```


Mixed compile/runtime

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

        constexpr refl::Type pointerToMember = member.get_pointer();
        std::cout
            << member.get_name()
            << "=" << unreflexpr(pointerToMember);

        saw_prev = true;
    }
    std::cout << "}" << std::endl;
}

struct S {
    std::string m_s;
    int m_i;
};

int main {
    dump( S{"hello", 33 } ); // outputs: { m_s="hello", m_i=33 }
}
```

## Requirements for feature parity with template metaprogramming reflexpr

The `for...` construct and constexpr-time allocatores are not, strictly
speaking, required for achieving feature parity with TMP-reflexpr. Uses of
`for...` could be replaced with a template-based iteration function. Custom,
fixed-size types could be used as alternative to compile-time allocators. There
is one thing that is critical, however, and that is `unreflexpr` for types.

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

## Typeful reflection

Some of the initial sketeches for constexpr-based reflection had the `reflexpr`
operation produce values that are always of the same type. While this has some
advantages to implementers, we feel that making proper use of types will
encourage programming that is easier to read and reason about.

## Sketch of data types and operations

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

## TODO

- Discuss the decision made for typeful reflected data types.
- Discuss the need to add non-template-metaprogramming-styled library
  features that already exist in the template metaprogramming form.

## Conclusion

