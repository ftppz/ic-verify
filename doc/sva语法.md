#三脚猫验证学习计划-第四课: SystemVerilog Assertions语法

读前须知:目前只有三大EDA厂商家的仿真器完全支持UVM和SV的语法, 因为他们是主要开发者和贡献者. 虽然UVM库代码开源, 但是开源软件目前不支持完整的SV和UVM, 望大家日后努力让开源软件也可以支持, 或者推动cocotb( :| 这个我还没学, hh)的发展.
##书籍导读
**SystemVerilog Assertions  应用指南** 本文简称 **SVA指南**
第一章 SVA介绍
并发断言->边沿/逻辑序列->交叠/非交叠->时序窗口->参数化->balabla...->cover

好了, 语法就这些, 很复杂, 不过常用那没那么多
**👇要看噢**
https://zhuanlan.zhihu.com/p/574208946
一个很nice的文章, 四个建议
1. 清晰的标签-方便verdi看
2. 简洁的断言代码-方便自己和同事看
3. 使用带参数的宏-减少浪费时间敲重复性代码
4. bind-方便管理SVA, 不然RTL和SVA交杂在一起, 还要找来找去

如果你在写C时经常使用assert, 就可以感觉到断言的功能强大, 省去很多打断点, debug的时间.
##实战训练
这部分没实战, 因为语法太过复杂, 而且比较万能.
需求和后面章节对应了, 看看相应章节就行.