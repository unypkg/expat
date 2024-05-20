#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154

set -vx

######################################################################################################################
### Setup Build System and GitHub

apt install -y autopoint

wget -qO- uny.nu/pkg | bash -s buildsys

### Installing build dependencies
#unyp install python

#pip3_bin=(/uny/pkg/python/*/bin/pip3)
#"${pip3_bin[0]}" install meson

### Getting Variables from files
UNY_AUTO_PAT="$(cat UNY_AUTO_PAT)"
export UNY_AUTO_PAT
GH_TOKEN="$(cat GH_TOKEN)"
export GH_TOKEN

source /uny/git/unypkg/fn
uny_auto_github_conf

######################################################################################################################
### Timestamp & Download

uny_build_date

mkdir -pv /uny/sources
cd /uny/sources || exit

pkgname="expat"
pkggit="https://github.com/libexpat/libexpat.git refs/tags/R_[0-9.]*"
gitdepth="--depth=1"

### Get version info from git remote
# shellcheck disable=SC2086
latest_head="$(git ls-remote --refs --tags --sort="v:refname" $pkggit | grep -E "R_[0-9](_[0-9]+)+$" | tail -n 1)"
latest_ver="$(echo "$latest_head" | cut --delimiter='/' --fields=3 | sed -e "s|R_||" -e "s|_|.|g")"
latest_commit_id="$(echo "$latest_head" | cut --fields=1)"

check_for_repo_and_create
git_clone_source_repo

cd "$pkg_git_repo_dir" || exit
mv expat ../expat
cd /uny/sources || exit
rm -r "$pkg_git_repo_dir"
cd expat || exit
./buildconf.sh
cd /uny/sources || exit
pkg_git_repo_dir=expat

version_details
archiving_source

######################################################################################################################
### Build

# unyc - run commands in uny's chroot environment
# shellcheck disable=SC2154
unyc <<"UNYEOF"
set -vx
source /uny/git/unypkg/fn

pkgname="expat"

version_verbose_log_clean_unpack_cd
get_env_var_values
get_include_paths

####################################################
### Start of individual build script

./configure --prefix=/uny/pkg/"$pkgname"/"$pkgver" \
    --disable-static \
    --docdir=/uny/pkg/"$pkgname"/"$pkgver"/share/doc/"$pkgname"

make -j"$(nproc)"
make -j"$(nproc)" check
make install

####################################################
### End of individual build script

add_to_paths_files
dependencies_file_and_unset_vars
cleanup_verbose_off_timing_end
UNYEOF

######################################################################################################################
### Packaging

package_unypkg
