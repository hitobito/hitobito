Fabricator(:pass_definition) do
  owner { Group.root }
  name { Faker::Lorem.unique.words(number: 3).join(" ") }
  template_key { "default" }
  background_color { "#0066cc" }

  transient logo_icon_path: nil, logo_banner_path: nil

  after_build do |definition, transients|
    lang = I18n.locale
    logo_icon = transients[:logo_icon_path] || Rails.root.join("spec", "fixtures", "files", "logo-icon.png")
    logo_banner = transients[:logo_banner_path] || Rails.root.join("spec", "fixtures", "files", "logo-banner.png")

    definition.public_send(:"logo_icon_#{lang}").attach(
      io: logo_icon.open,
      filename: "icon.png",
      content_type: "image/png"
    )

    definition.public_send(:"logo_banner_#{lang}").attach(
      io: logo_banner.open,
      filename: "banner.png",
      content_type: "image/png"
    )

    definition.save(validate: false)
  end
end
