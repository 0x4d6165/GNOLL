#include "randomness.h"

#include <curl/curl.h>
#include <json-c/json.h>
#include <limits.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "external/pcg_basic.h"

#if USE_SECURE_RANDOM == 1
#include <bsd/stdlib.h>
#endif

// Callback function to handle the JSON response
size_t write_callback(void *contents, size_t size, size_t nmemb, void *userp) {
  size_t realsize = size * nmemb;
  json_object **json = (json_object **)userp;

  // Parse the JSON response
  json_object *parsed_json = json_tokener_parse((char *)contents);

  // Check if parsing was successful
  if (json_object_get_type(parsed_json) == json_type_object) {
    json_object_put(*json);  // Release the previous JSON object
    *json = parsed_json;
  }

  return realsize;
}

int curl_Random_Org() {
  CURL *curl;
  CURLcode res;

  int random_number = -1;

  // Initialize libcurl
  curl_global_init(CURL_GLOBAL_DEFAULT);

  // Create a curl handle
  curl = curl_easy_init();
  if (curl) {
    // Set the URL to the Random.org API endpoint
    curl_easy_setopt(curl, CURLOPT_URL,
                     "https://api.random.org/json-rpc/2/invoke");

    const char *api_key = getenv("RANDOM_ORG_API");
    // Check if the environment variable exists
    if (api_key == NULL) {
      fprintf(stderr, "Error: API key not found in the environment variable\n");
      return 1;
    }
    // Set the POST data
    char post_data[135];
    snprintf(
        post_data, sizeof(post_data),
        "{\"jsonrpc\":\"2.0\",\"method\":\"generateIntegers\",\"params\":{"
        "\"apiKey\":\"%s\",\"n\":1,\"min\":,\"max\":1000000000,\"replacement\":"
        "true,\"base\":10},\"id\":1}",
        api_key);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, post_data);

    // Set the callback function to handle the JSON response
    json_object *json_response = json_object_new_object();
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, json_response);
    // Perform the HTTP request
    res = curl_easy_perform(curl);

    if (res == CURLE_OK) {
      // Parse the response to get the random number
      json_object *value_obj;
      if (json_object_object_get_ex(json_response, "result", &value_obj)) {
        json_object *random_obj;
        if (json_object_object_get_ex(value_obj, "random", &random_obj)) {
          json_object *number_obj;
          if (json_object_object_get_ex(random_obj, "data", &number_obj)) {
            random_number = json_object_get_int(number_obj);
          }
        }
      }
    } else {
      fprintf(stderr, "curl_easy_perform() failed: %s\n",
              curl_easy_strerror(res));
    }

    // Cleanup
    curl_easy_cleanup(curl);
    json_object_put(json_response);
  }

  return random_number;
}

extern pcg32_random_t rng;

int get_random_uniformly() {
  int value;
#if USE_SECURE_RANDOM == 1
  value = (int)arc4random_uniform(INT_MAX);
#elif USE_SECURE_RANDOM == 0
  value = (int)pcg32_boundedrand_r(&rng, INT_MAX);
#elif USE_SECURE_RANDOM == 2
  value = curl_Random_Org();
#else
  value = (int)pcg32_boundedrand_r(&rng, INT_MAX);
#endif
  return value;
}

double get_random_normally(double mean, double std) {
  /* Box-Muller. */
  // Not Cryptographically Secure yet.
  static double cached = 0.0;
  double res;
  if (cached == 0.0) {
    double x, y, r;
    do {
      x = 2.0 * (int)pcg32_boundedrand_r(&rng, INT_MAX) / UINT32_MAX - 1;
      y = 2.0 * (int)pcg32_boundedrand_r(&rng, INT_MAX) / UINT32_MAX - 1;
      r = x * x + y * y;
    } while (r == 0.0 || r > 1.0);

    double d = sqrt(-2.0 * log(r) / r);

    double n1 = x * d;
    double n2 = y * d;

    res = n1 * std + mean;
    cached = n2;
  } else {
    res = cached * std + mean;
    cached = 0.0;
  }

  if (res < -3 || res > 0) {
    // If outlier beyond bounds, reroll.
    // TODO: Catch Recusion Limit!!
    return get_random_normally(mean, std);
  }

  // The rest of the function only calculates one half
  int other_side = (int)pcg32_boundedrand_r(&rng, 2);
  if (other_side) {
    return res * -1;
  }

  return res;
}
