#!/bin/sh

eval "$(shellspec - -c) exit 1"

# shellcheck source=../string.shlib
. "${PROJECT_ROOT_DIR}/string.shlib"

Describe 'string.shlib'

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

    It 'replaces .. with horizontal ellipsis'
      When call unicodify_punctuation 'a..b'
      The status should be success
      The stdout should equal 'a…b'
    End

    It 'replaces ... with horizontal ellipsis'
      When call unicodify_punctuation 'a...b'
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

    It 'replaces multiple punctuation characters'
      When call unicodify_punctuation 'fix/foo: handle (bar) & baz'
      The status should be success
      The stdout should include '⁄'
      The stdout should include '（'
      The stdout should include '）'
      The stdout should include '＆'
    End

  End

End
