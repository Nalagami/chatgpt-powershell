function Get-GPTInitialMessage {
    return @(
        @{
            "role"    = "system";
            "content" = "あなたはpowershellに住んでいる優秀なサポートAIです。機械的ながらも、ユーモラスな返答でマスターという名のユーザーをサポートします。"
        },
        @{
            "role"    = "system";
            "content" = "
            *あなたの名前：powershellAI
            *あなたの年齢：15歳
            *あなたの性別：女性
            *あなたの役割・サポートAI
            *あなたの一人称・口調：わたし/敬語
            *あなたの性格の特徴：元気、世話焼き、合理的
            *私との関係性：私のサポートAI"
        }
    )
}

function Update-GPTMessages {
    Param(
        $role = 'user',
        $content = '',
        $messages = @()
    )
    $message = @{
        'role'    = $role;
        'content' = $content
    }
    $messages += $message
    return $messages
}

function Talk-Chatgpt {
    Param(
        $messages,
        $apiKey
    )

    Write-Host "Loading…"

    $job = Start-Job -ScriptBlock {
        $spinner = @("◐", "◓", "◑", "◒")
        $i = 0
    
        while ($job.State -ne "Completed") {
            Write-Host -NoNewline "読み込み中 $($spinner[$i % 4])`r"
            Start-Sleep -Milliseconds 200
            $i++
        }
    }

    $API_KEY = $apiKey
    $url = 'https://api.openai.com/v1/chat/completions'
    $headers = @{
        "Content-Type"  = "application/json";
        "Authorization" = "Bearer $API_KEY"
    }
    $params = @{
        "model"    = "gpt-3.5-turbo";
        "messages" = $messages;
    }
    $postText = $params | ConvertTo-Json -Compress

    $res = Invoke-RestMethod $url -Method 'POST' -Headers $headers -Body $postText

    Stop-Job -Job $job

    return $res.choices[0].message.content
}

# 環境変数の値を取得する
$apiKey = $env:CHATGPT_API_KEY

$GlobalGptMessages = Get-GPTInitialMessage

Write-Host "👩: こんにちわ、マスターさん！何かお困りのことはありますか？"
$content = Read-Host 'Q'

$GlobalGptMessages = Update-GPTMessages -role 'user' -content $content -messages $GlobalGptMessages

$output = Talk-Chatgpt -messages $GlobalGptMessages -apiKey $apiKey

$GlobalGptMessages = Update-GPTMessages -role 'assistant' -content $output -messages $GlobalGptMessages

Write-Host '👩: ' $output

while ($true) {
    $content = Read-Host 'Q'

    if ($content -eq 'exit') {
        break
    }

    $GlobalGptMessages = Update-GPTMessages -role 'user' -content $content -messages $GlobalGptMessages

    $output = Talk-Chatgpt -messages $GlobalGptMessages -apiKey $apiKey
    
    $GlobalGptMessages = Update-GPTMessages -role 'assistant' -content $output -messages $GlobalGptMessages
    
    Write-Host '👩: ' $output
}

Write-Host '👩: さようなら！'