/*******************************************************************************
 *
 * FILE NAME: psa.c
 *
 * PURPOSE: Cilk Parallel Suffix Array
 *
 * Compile: gcc -std=c11 -o psa psa.c -fcilkplus -lcilkrts
 *
 *
 *******************************************************************************/

#include <stdio.h>
#include <cilk/cilk.h>
#include <cilk/cilk_api.h>
#include <cilk/common.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <sys/time.h>
#include <string.h>
#define MAX_ARRAY 1000000

#ifdef MALLOC_COUNT
#include "malloc_count.h"
#endif

#define max(a, b) (((a) > (b)) ? (a) : (b))
#define min(a,b) ((a) < (b) ? (a) : (b))

char *A;
unsigned idx; /* size of input */
int threshold;
// An iterative implementation of quick sort

// A utility function to swap two elements
void swap ( int* a, int* b ) {
    int t = *a;
    *a = *b;
    *b = t;
}

/* This function is same in both iterative and recursive*/
int partition (char *arr, int l, int h, int *B) {

    int i = (l - 1);

    for (int j = l; j <= h - 1; j++) {
      //      int s = max(B[j], B[h]);
      //      if (memcmp(&arr[B[j]], &arr[B[h]], (idx-s)) < 1) {
      if (strcmp(&arr[B[j]], &arr[B[h]]) < 1) {
	i++;
	swap (&B[i], &B[j]);
      }
    }
    swap (&B[i + 1], &B[h]);
    //return (i + 1);
    return (h+l)/2;
}

/* A[] --> Array to be sorted, l  --> Starting index, h  --> Ending index */
void quickSortIterative (char *arr, int l, int h, int *B, int s)
{
    int n = h - l + 1;
    //for(int i=0; i < n; i++) B[s+1] = l + i;

    l = s; h = s + n - 1;
    // Create an auxiliary stack
    int *stack = malloc(sizeof(int)*n);

    // initialize top of stack
    int top = -1;

    // push initial values of l and h to stack
    stack[ ++top ] = l;
    stack[ ++top ] = h;

    // Keep popping from stack while is not empty
    //printf("---------IN---");
    while ( top >= 0 )
    {
        // Pop h and l
        h = stack[ top-- ];
        l = stack[ top-- ];

        // Set pivot element at its correct position in sorted array
//        printf("entre");
        int p = partition (arr, l, h, B);
	//int p = (l+h)/2;
  //      printf("sali");
        // If there are elements on left side of pivot, then push left
        // side to stack
        if ( p-1 > l )
        {
            stack[ ++top ] = l;
            stack[ ++top ] = p - 1;
        }

        // If there are elements on right side of pivot, then push right
        // side to stack
        if ( p+1 < h )
        {
            stack[ ++top ] = p + 1;
            stack[ ++top ] = h;
        }
    }
    //printf("--------OUT----");
}

//======= end quicksort ===============================

int cmpfunc (const void * a, const void * b) {
  return strcmp(&A[*(int*)a], &A[*(int*)b]);
}


int binsearch(char* S, int x, int *T, int p, int r) {
	int low, high, mid;
	low = p;
	high = max(p, r + 1);
	while (low < high) {
		mid = floor((low + high) / 2);
		if (strcmp(&S[x], &S[T[mid]]) < 1)
			//    if (S[x] <= S[T[mid]])
			high = mid;
		else
			low = mid + 1;
	}
	return high;
}

void pmerge(char* S, int *T, int p1, int r1, int p2, int r2, int *A, int p3) {
	int n1 = r1 - p1 + 1;
	int n2 = r2 - p2 + 1;
	if (n1 < n2) {
		swap(&p1, &p2);
		swap(&r1, &r2);
		swap(&n1, &n2);
	}
	if (n1 == 0) return;
	else {
		int q1 = (p1 + r1) / 2;
		int q2 = binsearch(S, T[q1], T, p2, r2);
		int q3 = p3 + (q1 - p1) + (q2 - p2);
		A[q3] = T[q1];
		cilk_spawn pmerge(S, T, p1, q1 - 1, p2, q2 - 1, A, p3);
		pmerge(S, T, q1 + 1, r1, q2, r2, A, q3 + 1);
		cilk_sync;
	}
}

void quickSortC(int p, int r, int* B, int s, int n){
  for(int i=0; i<n; i++)
    B[s+i] = p+i;


  qsort(&B[s], n, sizeof(int), cmpfunc);
}

void pmergesort(char *A, int p, int r, int *B, int s) {
  int n = r - p + 1;
  if (n == 1)
    B[s] = p;
  else if(n<threshold){
    quickSortC(p, r, B, s, n); 	
  //    quickSortIterative(A, p, r, B, s); 	
  }
  else {
    int q1 = (p + r) / 2;
    int q2 = q1 - p + 1;	  
    int *T = malloc(n * sizeof(int));
    if (!T) {
      puts("Error: malloc failed.");
      exit(EXIT_FAILURE);
    }
    cilk_spawn pmergesort(A, p, q1, T, 0);
    pmergesort(A, q1 + 1, r, T, q2);
    cilk_sync;
    pmerge(A, T, 0, q2 - 1, q2, n - 1, B, s);
  }
}


char* read_text_from_file(const char* fn, unsigned int* n) {

  FILE* fp = fopen(fn, "r");
  if (!fp) {
    fprintf(stderr, "Error opening file \"%s\".\n", fn);
    exit(-1);
  }

  fseek(fp, 0L, SEEK_END);
  *n = ftell(fp);

  char* t;
  t = malloc(*n);
  /*
  *n = *n / sizeof(unsigned int); // Number of symbols
  */
  fseek(fp, 0L, SEEK_SET);
  fread(t, 1, *n, fp);
  (*n)--;
  t[*n]='\0';

  fclose(fp);

  return t;

}


int main(int argc, char **argv) {
  
  if (argc != 3) {
    printf("*** ERROR: Usage: %s <data file> <threshold>\n", argv[0]);
    exit(EXIT_FAILURE);
  }
  
  //  struct timeval t0, t1;
  //	unsigned idx; /* size of input */
  
  A = read_text_from_file(argv[1],&idx); /* Input String */
  //idx = readfile(argv[1], A);
  //        printf("---------------------1--------------------------");
  int *B = malloc(idx * (sizeof(int))); /* output Suffix Array */
  /* Build */
  threshold = atoi(argv[2]);
#ifdef MALLOC_COUNT
  size_t s_total_memory = malloc_count_total();
  size_t s_current_memory = malloc_count_current();
  malloc_reset_peak();
  
#else
  struct timespec stime, etime;
  if (clock_gettime(CLOCK_MONOTONIC , &stime)) {
    fprintf(stderr, "clock_gettime failed");
    exit(-1);
  }
#endif
  
  pmergesort(A, 0, idx - 1, B, 0);
  
#ifdef MALLOC_COUNT
  size_t e_total_memory = malloc_count_total();
  size_t e_current_memory = malloc_count_current();
  printf("%s, %zu, %zu, %zu, %zu, %zu\n", argv[1], s_total_memory, e_total_memory, malloc_count_peak(), s_current_memory, e_current_memory);
  
#else
  if (clock_gettime(CLOCK_MONOTONIC , &etime)) {
    fprintf(stderr, "clock_gettime failed");
    exit(-1);
  }

  double t = (etime.tv_sec - stime.tv_sec) + (etime.tv_nsec - stime.tv_nsec) / 1000000000.0;
  printf("%d,%s,%u,%lf\n", __cilkrts_get_nworkers(), argv[1], idx, t);
#endif

  /*	gettimeofday(&t0, 0);
      	pmergesort(A, 0, idx - 1, B, 0);
	//quickSortIterative(A, 0, idx - 1, B, 0); 	
	gettimeofday(&t1, 0);

	printf("sort time: %f\n",
	double	(t1.tv_sec - t0.tv_sec) + ((t1.tv_usec - t0.tv_usec) / 1000000.0));

	printf("length: %d\n", idx);

	printf("%d,%s,%u,%lf\n", __cilkrts_get_nworkers(), argv[1], n, t);
  */
//	printf("Text: %s", A);
/*	if (idx < 50) {
		for (int i = 2; i< idx; i++)
			printf("%d: %s", B[i], &A[B[i]]);
	}
*/
	return 0;
}
