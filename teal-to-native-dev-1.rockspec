rockspec_format = "3.0"
package = "teal-to-native"
version = "dev-1"
source = {
   url = "git+https://github.com/Frityet/teal-to-native.git"
}
description = {
   homepage = "https://github.com/Frityet/teal-to-native",
   license = "MIT"
}
build_dependencies = {
   "cyan"
}
dependencies = {
   "lua ~> 5.4"
}
build = {
   type = "command",
   build_command = "cyan build"
}
