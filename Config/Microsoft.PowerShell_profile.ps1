oh-my-posh init powershell --config %LocalAppData%\Programs\oh-my-posh\themes/unicorn.omp.json | Invoke-Expression
Import-Module -Name Terminal-Icons

Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows