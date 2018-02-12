constexprreflexpr.html : constexprreflexpr.md
	pandoc --toc --self-contained --standalone --output $@ $<
