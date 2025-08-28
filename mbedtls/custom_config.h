/*
 * Custom mbedTLS configuration for RetroArch
 * Force TLS 1.2 only for simplicity and compatibility
 */

#include "mbedtls/mbedtls_config.h"

/* Disable TLS 1.3 to avoid PSA crypto complexity */
#undef MBEDTLS_SSL_PROTO_TLS1_3