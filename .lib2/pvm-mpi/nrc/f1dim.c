#ifndef __F1DIM_H__
#define __F1DIM_H__

double f1dim(double x);

#ifndef __HEADERS__
#include <pvm.h>

extern int ncom;
extern double *pcom,*xicom,(*nrfunc)(double []);

double f1dim(double x)
{
	int j;
	double f,*xt;

	xt=dvector(1,ncom);
	for (j=1;j<=ncom;j++) xt[j]=pcom[j]+x*xicom[j];
	f=(*nrfunc)(xt);
	free(xt+1);
	return f;
}
#endif
#endif
