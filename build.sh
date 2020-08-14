#!/usr/bin/env bash
set -eou pipefail
cd `dirname "$0"`

TZ=${TZ:-America/Sao_Paulo}
DESKTOP_VERSION=${DESKTOP_VERSION:-true}
TERMUX_VERSION=${TERMUX_VERSION:-true}
ASCIIDOCTOR_IMAGE=${ASCIIDOCTOR_IMAGE:-asciidoctor/docker-asciidoctor}
ASCIIDOCTOR_MULTIPAGE_IMAGE=${ASCIIDOCTOR_MULTIPAGE_IMAGE:-paulojeronimo/asciidoctor-multipage:1.5.7.1}

my-environment() {
  command -v termux-setup-storage &> /dev/null && echo termux || echo desktop
}

build-multipage-version() {
  case "`my-environment`" in
    desktop)
      asciidoctor() {
        docker run -it -e TZ=$TZ --rm \
          -v "$PWD":/documents $ASCIIDOCTOR_MULTIPAGE_IMAGE "$@"
      }
      ;;
    termux)
      cat <<-EOF
			Skipping the call to "$FUNCNAME" for termux environment!
			Reason: termux can not run Docker (Yet! Maybe someday!?)
			Follow this link: https://www.reddit.com/r/termux/comments/av6z2s/how_to_install_docker_on_termux/ehd5yus/
			EOF
      return 0
  esac
  asciidoctor -a linkcss index.adoc -D build/multipage
}

build-singlepage-version() {
  case "`my-environment`" in
    desktop)
      asciidoctor() {
        docker run -it -e TZ=$TZ --rm \
          -v "$PWD":/documents $ASCIIDOCTOR_IMAGE asciidoctor "$@"
      }
      ;;
    termux)
      which asciidoctor &> /dev/null || {
        # Fix an issue
        mkdir -p /data/data/com.termux/cache/apt/archives/partial
        # Install the required packages to run the next commands
        yes | pkg install asciidoctor tree
      }
  esac
  asciidoctor -a linkcss index.adoc -D build/singlepage
}

rm -rf build

echo "Building content in `my-environment` environment ..."
build-multipage-version
build-singlepage-version

echo "Generated content (the \"build\" directory tree shown below):"
tree build
