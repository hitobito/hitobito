const { environment } = require('@rails/webpacker')
const wagonFile = require('./loaders/wagon-file')
const coffee =  require('./loaders/coffee')
const erb = require('./loaders/erb')
const webpack = require('webpack')

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
sass.use = sass.use.filter(({loader}) => loader !== 'postcss-loader')

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

module.exports = environment
