process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')
const config = environment.toWebpackConfig()

// The wagon require.context in controllers/index.js watches a broad parent directory
// (../../../../) to discover wagon controllers. This causes webpack to watch the entire
// app/ tree including public/packs/, tmp/, log/, etc. — triggering spurious recompiles.
// Whitelist only app/javascript and app/components (webpack's actual source directories)
// so the watcher ignores everything outside those paths.
const onlyWatchSourceDirs = (absolutePath) => {
  return !["/app/javascript/", "/app/components/"].some((dir) =>
    absolutePath.includes(dir)
  )
}

config.watchOptions = { ...config.watchOptions, ignored: onlyWatchSourceDirs }
if (config.devServer) {
  config.devServer.watchOptions = {
    ...config.devServer.watchOptions,
    ignored: onlyWatchSourceDirs,
  }
}

module.exports = config
