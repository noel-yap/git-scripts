#!/bin/sh

eval "$(shellspec - -c) exit 1"

# shellcheck source=../string.shlib
. "${PROJECT_ROOT_DIR}/string.shlib"

Describe 'string.shlib'

  Describe '_punc_sub_re_to_ascii'

    It 'maps the ellipsis regex to three dots'
      When call _punc_sub_re_to_ascii '\.\.\.\.*'
      The status should be success
      The stdout should equal '...'
    End

    It 'unescapes a backslash-escaped sed regex key'
      When call _punc_sub_re_to_ascii '\/'
      The status should be success
      The stdout should equal '/'
    End

    It 'passes through a literal punctuation character unchanged'
      When call _punc_sub_re_to_ascii ';'
      The status should be success
      The stdout should equal ';'
    End

    It 'unescapes a multi-character escaped regex key'
      When call _punc_sub_re_to_ascii '\.\.'
      The status should be success
      The stdout should equal '..'
    End

  End

  Describe 'inverse_punc_subs'

    inverse_lookup() {
      local -A _inv
      inverse_punc_subs _inv
      printf '%s' "${_inv[$1]}"
    }

    It 'maps fraction slash back to slash'
      When call inverse_lookup '⁄'
      The status should be success
      The stdout should equal '/'
    End

    It 'maps horizontal ellipsis back to three dots'
      When call inverse_lookup '…'
      The status should be success
      The stdout should equal '...'
    End

    It 'maps two dot leader back to two dots'
      When call inverse_lookup '‥'
      The status should be success
      The stdout should equal '..'
    End

    It 'maps fullwidth colon back to colon'
      When call inverse_lookup '：'
      The status should be success
      The stdout should equal ':'
    End

  End

  Describe 'unicodify_punctuation'

    It 'passes through plain text unchanged'
      When call unicodify_punctuation 'helloworld'
      The status should be success
      The stdout should equal 'helloworld'
    End

    It 'replaces / with fraction slash'
      When call unicodify_punctuation 'a/b'
      The status should be success
      The stdout should equal 'a⁄b'
    End

    It 'leaves a single dot unchanged'
      When call unicodify_punctuation 'a.b'
      The status should be success
      The stdout should equal 'a.b'
    End

    It 'replaces .. with two dot leader'
      When call unicodify_punctuation 'a..b'
      The status should be success
      The stdout should equal 'a‥b'
    End

    It 'replaces ... with horizontal ellipsis'
      When call unicodify_punctuation 'a...b'
      The status should be success
      The stdout should equal 'a…b'
    End

    It 'replaces four or more dots with horizontal ellipsis'
      When call unicodify_punctuation 'a....b'
      The status should be success
      The stdout should equal 'a…b'
    End

    It 'replaces ? with fullwidth question mark'
      When call unicodify_punctuation 'a?b'
      The status should be success
      The stdout should equal 'a？b'
    End

    It 'replaces * with fullwidth asterisk'
      When call unicodify_punctuation 'a*b'
      The status should be success
      The stdout should equal 'a＊b'
    End

    It 'replaces space with en space'
      en_space="$(printf '\xe2\x80\x82')"
      When call unicodify_punctuation 'a b'
      The status should be success
      The stdout should equal "a${en_space}b"
    End

    It 'replaces ; with fullwidth semicolon'
      When call unicodify_punctuation 'a;b'
      The status should be success
      The stdout should equal 'a；b'
    End

    It 'replaces & with fullwidth ampersand'
      When call unicodify_punctuation 'a&b'
      The status should be success
      The stdout should equal 'a＆b'
    End

    It 'replaces | with fullwidth vertical line'
      When call unicodify_punctuation 'a|b'
      The status should be success
      The stdout should equal 'a｜b'
    End

    It 'replaces ( with fullwidth left parenthesis'
      When call unicodify_punctuation 'a(b'
      The status should be success
      The stdout should equal 'a（b'
    End

    It 'replaces ) with fullwidth right parenthesis'
      When call unicodify_punctuation 'a)b'
      The status should be success
      The stdout should equal 'a）b'
    End

    It 'replaces { with fullwidth left curly bracket'
      When call unicodify_punctuation 'a{b'
      The status should be success
      The stdout should equal 'a｛b'
    End

    It 'replaces } with fullwidth right curly bracket'
      When call unicodify_punctuation 'a}b'
      The status should be success
      The stdout should equal 'a｝b'
    End

    It 'replaces [ with fullwidth left bracket'
      When call unicodify_punctuation 'a[b'
      The status should be success
      The stdout should equal 'a［b'
    End

    It 'replaces ] with fullwidth right bracket'
      When call unicodify_punctuation 'a]b'
      The status should be success
      The stdout should equal 'a］b'
    End

    It 'replaces < with fullwidth less-than sign'
      When call unicodify_punctuation 'a<b'
      The status should be success
      The stdout should equal 'a＜b'
    End

    It 'replaces > with fullwidth greater-than sign'
      When call unicodify_punctuation 'a>b'
      The status should be success
      The stdout should equal 'a＞b'
    End

    It 'replaces ~ with fullwidth tilde'
      When call unicodify_punctuation 'a~b'
      The status should be success
      The stdout should equal 'a～b'
    End

    It 'replaces $ with fullwidth dollar sign'
      When call unicodify_punctuation 'a$b'
      The status should be success
      The stdout should equal 'a＄b'
    End

    It 'replaces \ with fullwidth reverse solidus'
      When call unicodify_punctuation 'a\b'
      The status should be success
      The stdout should equal 'a＼b'
    End

    It "replaces ' with fullwidth apostrophe"
      When call unicodify_punctuation "a'b"
      The status should be success
      The stdout should equal 'a＇b'
    End

    It 'replaces " with fullwidth quotation mark'
      When call unicodify_punctuation 'a"b'
      The status should be success
      The stdout should equal 'a＂b'
    End

    It 'replaces # with fullwidth number sign'
      When call unicodify_punctuation 'a#b'
      The status should be success
      The stdout should equal 'a＃b'
    End

    It 'replaces : with fullwidth colon'
      When call unicodify_punctuation 'a:b'
      The status should be success
      The stdout should equal 'a：b'
    End

    It 'replaces multiple punctuation characters'
      When call unicodify_punctuation 'fix/foo: handle (bar) & baz'
      The status should be success
      The stdout should include '⁄'
      The stdout should include '（'
      The stdout should include '）'
      The stdout should include '＆'
    End

  End

  Describe 'deunicodify_punctuation'

    It 'passes through plain text unchanged'
      When call deunicodify_punctuation 'helloworld'
      The status should be success
      The stdout should equal 'helloworld'
    End

    It 'restores space from en space'
      en_space="$(printf '\xe2\x80\x82')"
      When call deunicodify_punctuation "a${en_space}b"
      The status should be success
      The stdout should equal 'a b'
    End

    It 'restores : from fullwidth colon'
      When call deunicodify_punctuation 'a：b'
      The status should be success
      The stdout should equal 'a:b'
    End

    It 'restores & from fullwidth ampersand'
      When call deunicodify_punctuation 'a＆b'
      The status should be success
      The stdout should equal 'a&b'
    End

    It 'restores parentheses from fullwidth parentheses'
      When call deunicodify_punctuation 'a（b）c'
      The status should be success
      The stdout should equal 'a(b)c'
    End

    It 'restores ... from horizontal ellipsis'
      When call deunicodify_punctuation 'a…b'
      The status should be success
      The stdout should equal 'a...b'
    End

    It 'restores .. from two dot leader'
      When call deunicodify_punctuation 'a‥b'
      The status should be success
      The stdout should equal 'a..b'
    End

    It 'round-trips a unicodified summary back to ASCII'
      round_trip() {
        deunicodify_punctuation "$(unicodify_punctuation "$1")"
      }
      When call round_trip 'fix/foo: handle (bar) & baz'
      The status should be success
      The stdout should equal 'fix/foo: handle (bar) & baz'
    End

  End

End
