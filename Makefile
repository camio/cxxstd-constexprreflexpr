constexprreflexpr.html : constexprreflexpr.md
	pandoc --toc --standalone --output $@ $<
