<#
  ProfileActions.psm1
  - Windows Terminal の settings.json にプロファイルを追加するヘルパー
  - 依存: scripts/Get-WindowsTerminalSettingsPath.ps1
  - 使い方例:
    Profile-Add -Name 'XUMI' -RawJson '"opacity":70, "useAcrylic":true, "backgroundImage":"xumi_sofa.png"'
#>

function Profile-Add {
  [CmdletBinding()] param(
    [Parameter(Mandatory=$true)][string]$Name,
    [string]$RawJson
  )

  $scriptsRoot = Split-Path $PSScriptRoot -Parent
  $repoRoot    = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

  # Get-WindowsTerminalSettingsPath を読み込み
  . (Join-Path $scriptsRoot 'Get-WindowsTerminalSettingsPath.ps1')
  $settingsPath = Get-WindowsTerminalSettingsPath
  if (-not $settingsPath) { throw 'Windows Terminal の settings.json が見つからないよ' }

  # JSON を読み込み（編集しやすいように Hashtable）
  $json = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8
  $doc  = ConvertFrom-Json -InputObject $json -AsHashtable

  # profiles の場所を見つける: 新形式 { profiles: { list: [] } } / 旧形式 { profiles: [] }
  $profilesList = $null
  if ($doc.ContainsKey('profiles')) {
    $pnode = $doc['profiles']
    if ($pnode -is [hashtable]) {
      if (-not $pnode.ContainsKey('list') -or $null -eq $pnode['list']) { $pnode['list'] = @() }
      $profilesList = $pnode['list']
    } elseif ($pnode -is [System.Array]) {
      $profilesList = $pnode
    }
  } else {
    # 無ければ新形式で作成
    $doc['profiles'] = @{ list = @() }
    $profilesList = $doc['profiles']['list']
  }

  # 追加プロファイルの組み立て（必須/既定）
  $guid = '{' + ([guid]::NewGuid().ToString()) + '}'
  $profile = [ordered]@{
    guid   = $guid
    name   = $Name
    hidden = $false
  }

  # 任意パラメータ（RawJson は { ... } の中身想定。丸ごと渡したい場合はそのままでもOK）
  if (-not [string]::IsNullOrWhiteSpace($RawJson)) {
    $frag = $RawJson.Trim()
    if ($frag -match '^\{') { $extra = ConvertFrom-Json -InputObject $frag -AsHashtable }
    else                     { $extra = ConvertFrom-Json -InputObject ('{' + $frag + '}') -AsHashtable }
    foreach ($k in $extra.Keys) {
      $v = $extra[$k]
      if ($k -in @('backgroundImage','icon') -and ($v -is [string])) {
        $val = [string]$v
        # ファイル名のみなら既定ディレクトリに解決（images/icons）
        if ($val -notmatch '[\\/]' -and $val -notmatch '^[A-Za-z]:') {
          $base = if ($k -eq 'backgroundImage') { Join-Path $repoRoot 'images' } else { Join-Path $repoRoot 'icons' }
          $val = Join-Path $base $val
        }
        try {
          $rp = Resolve-Path -LiteralPath $val -ErrorAction Stop
          $val = $rp.Path
        } catch { }
        # WTの例に合わせてスラッシュ区切りへ正規化
        $profile[$k] = ($val -replace '\\','/')
      } else {
        $profile[$k] = $v
      }
    }
  }

  # 既存と重複なら置換（name or guid）
  $asList = $profilesList
  $isArray = $asList -is [object[]]
  if ($isArray) { $asList = New-Object System.Collections.ArrayList ($profilesList) }

  $idx = -1
  for ($i=0; $i -lt $asList.Count; $i++) {
    $p = $asList[$i]
    $pn = $p.name; $pg = $p.guid
    if ($pn -eq $profile['name'] -or $pg -eq $profile['guid']) { $idx = $i; break }
  }
  if ($idx -ge 0) { $asList[$idx] = $profile }
  else            { [void]$asList.Add($profile) }

  if ($doc['profiles'] -is [hashtable]) {
    $doc['profiles']['list'] = $asList
  } else {
    $doc['profiles'] = $asList
  }

  # JSON を書き戻し（十分な深さ）
  $out = ConvertTo-Json -InputObject $doc -Depth 100
  Set-Content -LiteralPath $settingsPath -Value $out -Encoding UTF8

  Write-Host ("WT settings updated: {0}" -f $settingsPath) -ForegroundColor Green
}

Export-ModuleMember -Function Profile-Add

