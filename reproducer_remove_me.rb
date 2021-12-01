# frozen_string_literal: true

THEME_PATH = "/Users/karreiro/src/github.com/Shopify/my_theme"

def update_file(seed)
  path = "#{THEME_PATH}/assets/file#{seed}.js"
  puts "→ #{path}"
  cmd = "echo \"/*`date`*/ * { zoom: 1 }\" > #{path}"
  system(cmd)
  sleep(0.1)
end

def update_section(section)
  file = "#{THEME_PATH}/sections/#{section}.liquid"
  puts "→ #{file}"
  text = File.read(file)
  new_contents = text.gsub(/style\=\"background-color\:.*\"/, "style=\"background-color: \##{rand.to_s[2..7]}\"")
  File.open(file, "w") { |f| f.puts new_contents }
end

def update_announcement_bar
  file = "#{THEME_PATH}/sections/announcement-bar.liquid"
  puts "→ #{file}"
  text = File.read(file)
  new_contents = text.gsub(/<div.*class="announcement-bar color/, "<div style=\"background-color: \##{rand.to_s[2..7]}\" class=\"announcement-bar color")
  File.open(file, "w") { |f| f.puts new_contents }
end

def update_theme_liquid
  file = "#{THEME_PATH}/layout/theme.liquid"
  puts "→ #{file}"
  text = File.read(file)
  new_contents = text.gsub(/<body class="gradient.*/, "<body class=\"gradient\"><h1>🧪 TEST: #{Time.now}!</h1>")
  File.open(file, "w") { |f| f.puts new_contents }
end

## 10.times { |i| update_file(i) }

update_announcement_bar
update_theme_liquid

## update_section('main-cart-items')