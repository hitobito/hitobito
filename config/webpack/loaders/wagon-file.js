const { join, normalize } = require('path')
const { source_path: sourcePath, static_assets_extensions: fileExtensions } = require('@rails/webpacker/package/config')


const corePath = process.cwd();
const coreSourcePath = normalize(join(corePath, sourcePath));

module.exports = {
  test: new RegExp(`(${fileExtensions.join('|')})$`, 'i'),
  use: [
    {
      loader: 'file-loader',
      options: {
        name(file) {
          if (file.includes(normalize(sourcePath))) {
            if (file.startsWith(coreSourcePath)) {
              // File from hitobito core, make available under default URL
              return 'media/[path][name]-[hash].[ext]'
            }
            // File from hitobito wagon, make available under seperate
            // URL for the `wagon_*_pack_*` helpers to be able to
            // reference it
            return `wagon-media/[folder]/[name]-[hash].[ext]`
          }
          return 'media/[folder]/[name]-[hash:8].[ext]'
        },
        esModule: false,
        context: join(sourcePath)
      }
    }
  ]
}
