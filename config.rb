###
# Compass
###

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Reload the browser automatically whenever files change
# configure :development do
#   activate :livereload
# end

###
# Helpers
###

# Methods defined in the helpers block are available in templates
helpers do
  def markdown(source)
    renderer = Redcarpet::Render::HTML.new({})
    markdown = Redcarpet::Markdown.new(renderer, {})
    html = markdown.render(source)
    Redcarpet::Render::SmartyPants.render html
  end

  def pseudo_host
    if build?
      "http://www.jonikorpi.com"
    else
      if defined?(req) && req.env["HTTP_HOST"]
        if req.env["REQUEST_URI"] =~ /\Ahttps/i
          "https://#{req.env["HTTP_HOST"]}"
        else
          "http://#{req.env["HTTP_HOST"]}"
        end
      else
        "http://localhost:4567"
      end
    end
  end

  def image_url(*args)
    pseudo_host + image_path(*args)
  end

  def current_page_url
    pseudo_host + current_page.url
  end
end

set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true, :smartypants => true

activate :blog do |blog|
  blog.sources = "posts/{title}.html"
  blog.permalink = "{title}"
  blog.tag_template = "tag.html"
  blog.taglink = "{tag}"
end

activate :autoprefixer do |config|
  config.browsers = ['last 3 versions']
  config.remove = false
end

activate :directory_indexes
activate :syntax

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript

  # Enable cache buster
  activate :asset_hash

  # Use relative URLs
  # activate :relative_assets

  # Or use a different image path
  # set :http_prefix, "/Content/images/"
end
