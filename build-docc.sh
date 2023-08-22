##!/bin/sh

swift package generate-documentation --target UserDefault
xcrun docc process-archive transform-for-static-hosting \
    "$PWD/.build/plugins/Swift-DocC/outputs/UserDefault.doccarchive" \
    --output-path ".docs" \
    --hosting-base-path "UserDefaultMacro"
echo '<script>window.location.href += "/documentation/userdefault"</script>' > .docs/index.html