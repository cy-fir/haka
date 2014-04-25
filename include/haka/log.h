/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * \file
 * Logging API.
 */

#ifndef _HAKA_LOG_H
#define _HAKA_LOG_H

#include <wchar.h>
#include <haka/types.h>
#include <haka/container/list.h>


/**
 * Log level.
 */
typedef enum {
	HAKA_LOG_FATAL, /**< Fatal errors. */
	HAKA_LOG_ERROR, /**< Errors. */
	HAKA_LOG_WARNING, /**< Warning. */
	HAKA_LOG_INFO, /**< Informations. */
	HAKA_LOG_DEBUG, /**< Debugging informations. */

	HAKA_LOG_LEVEL_LAST /**< Last log level. */
} log_level;

/**
 * Convert a logging level to a human readable string.
 *
 * \returns A string representing the logging level. This string is constant and should
 * not be freed.
 */
const char *level_to_str(log_level level);

/**
 * Convert a logging level represented by a string to the matching
 * enum value.
 */
log_level str_to_level(const char *str);

/**
 * Log a message without string formating.
 */
void message(log_level level, const wchar_t *module, const wchar_t *message);

/**
 * Log a message with string formating.
 */
void messagef(log_level level, const wchar_t *module, const wchar_t *fmt, ...);

/**
 * Set the logging level to display for a given module name. The `module` parameter can be
 * `NULL` in which case it will set the default level.
 */
void setlevel(log_level level, const wchar_t *module);

/**
 * Get the logging level for a given module name.
 */
log_level getlevel(const wchar_t *module);

/**
 * Change the display of log message on stdout.
 */
void enable_stdout_logging(bool enable);

/**
 * Show a log line on the stdout.
 */
bool stdout_message(log_level lvl, const wchar_t *module, const wchar_t *message);

/**
 * Logger instance structure.
 */
struct logger {
	struct list   list;
	void        (*destroy)(struct logger *state);
	int         (*message)(struct logger *state, log_level level, const wchar_t *module, const wchar_t *message);
	bool          mark_for_remove; /**< \private */
};

/**
 * Add a new logger instance in the logger list.
 * Each logger will receive all logging messages that are
 * emitted by the code.
 */
bool add_logger(struct logger *logger);

/**
 * Remove a logger.
 */
bool remove_logger(struct logger *logger);

/**
 * Remove all loggers.
 */
void remove_all_logger();

#endif /* _HAKA_LOG_H */
