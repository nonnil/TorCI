import sass
import strutils

const srcPath: string = "index"
let outPath: string = "style"

compileFile("src/sass/" & $srcPath & ".scss", outputPath = "public/css/" & $outPath & ".css")
echo "\n"
echo "Cpmpiled to public/css/" & $outPath & ".css"