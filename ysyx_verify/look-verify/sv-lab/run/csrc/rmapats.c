// file = 0; split type = patterns; threshold = 100000; total count = 0.
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

void  hsG_0__0 (struct dummyq_struct * I1350, EBLK  * I1345, U  I708);
void  hsG_0__0 (struct dummyq_struct * I1350, EBLK  * I1345, U  I708)
{
    U  I1610;
    U  I1611;
    U  I1612;
    struct futq * I1613;
    struct dummyq_struct * pQ = I1350;
    I1610 = ((U )vcs_clocks) + I708;
    I1612 = I1610 & ((1 << fHashTableSize) - 1);
    I1345->I753 = (EBLK  *)(-1);
    I1345->I754 = I1610;
    if (0 && rmaProfEvtProp) {
        vcs_simpSetEBlkEvtID(I1345);
    }
    if (I1610 < (U )vcs_clocks) {
        I1611 = ((U  *)&vcs_clocks)[1];
        sched_millenium(pQ, I1345, I1611 + 1, I1610);
    }
    else if ((peblkFutQ1Head != ((void *)0)) && (I708 == 1)) {
        I1345->I756 = (struct eblk *)peblkFutQ1Tail;
        peblkFutQ1Tail->I753 = I1345;
        peblkFutQ1Tail = I1345;
    }
    else if ((I1613 = pQ->I1253[I1612].I776)) {
        I1345->I756 = (struct eblk *)I1613->I774;
        I1613->I774->I753 = (RP )I1345;
        I1613->I774 = (RmaEblk  *)I1345;
    }
    else {
        sched_hsopt(pQ, I1345, I1610);
    }
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
