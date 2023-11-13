#ifndef __RANDOMNESS_H__
#define __RANDOMNESS_H__

#include <stddef.h>

int get_random_uniformly();
double get_random_normally(double mean, double std);

int curl_Random_Org();

size_t write_callback(void *contents, size_t size, size_t nmemb, void *userp);

#endif
