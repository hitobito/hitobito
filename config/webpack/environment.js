const { environment } = require('@rails/webpacker')
const { sync: globSync } = require('glob')
const { basename, join: pathJoin, resolve: pathResolve } = require('path')
const { extensions } = require('@rails/webpacker/package/config')

const pathCompleteExtname = require('path-complete-extname')
const webpack = require('webpack')
const wagonFile = require('./loaders/wagon-file')
const coffee = require('./loaders/coffee')
const erb = require('./loaders/erb')

// Replace default file loader with custom wagon-aware file loader
const fileLoaderIndex = environment.loaders.findIndex(l => l.key === 'file');
environment.loaders[fileLoaderIndex].value = wagonFile

// Transpile CoffeeScript
environment.loaders.prepend('coffee', coffee)

// Allow to use .js.erb and .scss.erb templates
environment.loaders.append('erb', erb)

// Bundle images referenced within SASS files
const sass = environment.loaders.find(l => l.key === 'sass').value
sass.use.splice(-1, 0, { loader: 'resolve-url-loader' })

// Remove postcss-loader to avoid a parsing bug with PostCSS
// 7.0.39. This would be fixed with 8.4.31, but @rails/webpacker is
// not maintained anymore, so can't update.
sass.use = sass.use.filter(({ loader }) => loader !== 'postcss-loader')

// Old-school libraries must be made globally accessible by exposing
// them to the window object.
environment.loaders.append('expose query to window object', {
  test: require.resolve('jquery'),
  use: [{
    loader: 'expose-loader',
    options: {
      exposes: ['jQuery', '$'],
    }
  }]
})
environment.loaders.append('expose moment to window object', {
  test: require.resolve('moment'),
  use: [{
    loader: 'expose-loader',
    options: {
      exposes: 'moment',
    }
  }]
})

environment.plugins.append('exclude unused moment locales',
  new webpack.ContextReplacementPlugin(
    /moment[\\\/]locale$/,
    /^\.\/(en|de|fr|it)$/
  )
)

// Register webpack entry points from wagon directories (../hitobito_*/app/javascript/packs/*)
// This allows wagons to define their own layouts/pack files that get compiled into the manifest.

// For this to work in PRE_BUILD_SCRIPT, we need a pathJoin from
// vendor wagons aswell, instead of the local setup
const wagonExtGlob = extensions.length === 1
  ? `**/*${extensions[0]}`
  : `**/*{${extensions.join(',')}}`

const wagonPacksPatterns = [
  pathJoin('..', 'hitobito_*', 'app', 'javascript', 'packs', wagonExtGlob),
  pathJoin('vendor', 'wagons', 'hitobito_*', 'app', 'javascript', 'packs', wagonExtGlob),
]
wagonPacksPatterns.flatMap((pattern) => globSync(pattern)).forEach((packPath) => {
  const name = basename(packPath, pathCompleteExtname(packPath))
  const existingEntry = environment.entry.get(name) || []
  environment.entry.set(name, [...existingEntry, pathResolve(packPath)])
})

module.exports = environment
