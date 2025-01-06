// Betterfox version 130
/****************************************************************************
 * SECTION: FASTFOX                                                         *
****************************************************************************/
/** GENERAL ***/
pref("content.notify.interval", 100000);

/** GFX ***/
pref("gfx.canvas.accelerated.cache-items", 4096);
pref("gfx.canvas.accelerated.cache-size", 512);
pref("gfx.content.skia-font-cache-size", 20);

/** DISK CACHE ***/
pref("browser.cache.jsbc_compression_level", 9);

/** MEDIA CACHE ***/
pref("media.memory_cache_max_size", 65536);
pref("media.cache_readahead_limit", 7200);
pref("media.cache_resume_threshold", 3600);

/** IMAGE CACHE ***/
pref("image.mem.decode_bytes_at_a_time", 32768);

/** NETWORK ***/
pref("network.http.max-connections", 1800);
pref("network.http.max-persistent-connections-per-server", 10);
pref("network.http.max-urgent-start-excessive-connections-per-host", 5);
pref("network.http.pacing.requests.enabled", false);
// pref("network.dnsCacheExpiration", 3600);
pref("network.ssl_tokens_cache_capacity", 10240);

/** SPECULATIVE LOADING ***/
pref("network.dns.disablePrefetch", true);
pref("network.dns.disablePrefetchFromHTTPS", true);
pref("network.prefetch-next", false);
pref("network.predictor.enabled", false);
pref("network.predictor.enable-prefetch", false);

/** EXPERIMENTAL ***/
pref("layout.css.grid-template-masonry-value.enabled", true);
pref("dom.enable_web_task_scheduling", true);

/****************************************************************************
 * SECTION: SECUREFOX                                                       *
****************************************************************************/
/** TELEMETRY ***/
pref("datareporting.policy.dataSubmissionEnabled", false);
pref("datareporting.healthreport.uploadEnabled", false);
pref("toolkit.telemetry.unified", false);
pref("toolkit.telemetry.enabled", false);
pref("toolkit.telemetry.server", "data:,");
pref("toolkit.telemetry.archive.enabled", false);
pref("toolkit.telemetry.newProfilePing.enabled", false);
pref("toolkit.telemetry.shutdownPingSender.enabled", false);
pref("toolkit.telemetry.updatePing.enabled", false);
pref("toolkit.telemetry.bhrPing.enabled", false);
pref("toolkit.telemetry.firstShutdownPing.enabled", false);
pref("toolkit.telemetry.coverage.opt-out", true);
pref("toolkit.coverage.opt-out", true);
pref("toolkit.coverage.endpoint.base", "");
pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
pref("browser.newtabpage.activity-stream.telemetry", false);

/** EXPERIMENTS ***/
pref("app.shield.optoutstudies.enabled", false);
pref("app.normandy.enabled", false);
pref("app.normandy.api_url", "");

/** CRASH REPORTS ***/
pref("breakpad.reportURL", "");
pref("browser.tabs.crashReporting.sendReport", false);
pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);

/****************************************************************************
 * SECTION: CUSTOM                                                          *
****************************************************************************/
// Disable HTTP/3
pref("network.http.http3.enable", false);

// Disable insecure and inefficient cipher suites
pref("security.ssl3.ecdhe_ecdsa_aes_128_sha", false);
pref("security.ssl3.ecdhe_ecdsa_aes_256_gcm_sha384", false);
pref("security.ssl3.ecdhe_ecdsa_aes_256_sha", false);
pref("security.ssl3.ecdhe_ecdsa_chacha20_poly1305_sha256", false);
pref("security.ssl3.ecdhe_rsa_aes_128_sha", false);
pref("security.ssl3.ecdhe_rsa_aes_256_gcm_sha384", false);
pref("security.ssl3.ecdhe_rsa_aes_256_sha", false);
pref("security.ssl3.ecdhe_rsa_chacha20_poly1305_sha256", false);
pref("security.ssl3.rsa_aes_128_gcm_sha256", false);
pref("security.ssl3.rsa_aes_128_sha", false);
pref("security.ssl3.rsa_aes_256_gcm_sha384", false);
pref("security.ssl3.rsa_aes_256_sha", false);
pref("security.tls13.aes_256_gcm_sha384", false);
pref("security.tls13.chacha20_poly1305_sha256", false);
