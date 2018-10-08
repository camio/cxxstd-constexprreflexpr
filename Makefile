constexprreflexpr.html : constexprreflexpr.md
	pandoc --toc --self-contained --standalone --output $@ $<
	sed "s/<span class=\"dt\">get_type<\/span>/get_type/" -i $@
