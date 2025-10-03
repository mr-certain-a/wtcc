param(
  [Parameter(Mandatory=$true)][string]$Color
)

function Convert-ToOsc11Rgb {
  param([string]$InputColor)
  $c = $InputColor.Trim()
  # 受け付ける形式: #RGB / #RRGGBB / rgb:r/g/b / rgb:rrrr/gggg/bbbb
  if ($c -match '^#([0-9A-Fa-f]{3})$') {
    $r = $Matches[1][0]; $g = $Matches[1][1]; $b = $Matches[1][2]
    $rr = "$r$r"; $gg = "$g$g"; $bb = "$b$b"
    return ('rgb:{0}{0}/{1}{1}/{2}{2}' -f $rr,$gg,$bb)
  }
  elseif ($c -match '^#([0-9A-Fa-f]{6})$') {
    $hex = $Matches[1]
    $rr = $hex.Substring(0,2); $gg = $hex.Substring(2,2); $bb = $hex.Substring(4,2)
    # 8bit→16bitは単純複写（0xAB → 0xABAB）
    return ('rgb:{0}{0}/{1}{1}/{2}{2}' -f $rr,$gg,$bb)
  }
  elseif ($c -match '^rgb:([0-9A-Fa-f]{1,4})/([0-9A-Fa-f]{1,4})/([0-9A-Fa-f]{1,4})$') {
    $r=$Matches[1]; $g=$Matches[2]; $b=$Matches[3]
    # 1〜4桁を4桁へ0詰め
    $r = $r.PadLeft(4,'0'); $g = $g.PadLeft(4,'0'); $b = $b.PadLeft(4,'0')
    return ("rgb:$r/$g/$b")
  }
  else {
    # 不明形式はそのまま（WTが#RRGGBBを受ける場合もあるため）
    return $c
  }
}

$osc = Convert-ToOsc11Rgb -InputColor $Color
$esc = [char]0x1b; $bel = [char]0x07
Write-Host ("{0}]11;{1}{2}" -f $esc, $osc, $bel) -NoNewline
Write-Host ""  # 行末整形用に改行だけ出す
