#ifndef __RSOLV_H__
#define __RSOLV_H__

void rsolv(double **a, int n, double *d, double *b);

#ifndef __HEADERS__

void rsolv(double **a, int n, double *d, double *b)
{
	int i,j;
	double sum;

	b[n] /= d[n];
	for (i=n-1;i>=1;i--) {
		for (sum=0.0,j=i+1;j<=n;j++) sum += a[i][j]*b[j];
		b[i]=(b[i]-sum)/d[i];
	}
}
#endif
#endif
