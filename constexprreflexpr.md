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

Compile time

```c++
template <typename T>
void dump() {
    refl::Type t = reflexpr(T);
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
    refl::Type t = reflexpr(T);
    bool saw_prev = false;
    for...(RecordMember member : t.get_public_data_members())
    {
        if(saw_prev) {
            std::cout << ", ";
        }

        refl::Type pointerToMember = member.get_pointer();
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



## TODO

- Discuss the need for type reflection for feature parity.
- Discuss the decision made for typeful reflected data types.
- Discuss the need to add non-template-metaprogramming-styled library
  features that already exist in the template metaprogramming form.

## Conclusion

