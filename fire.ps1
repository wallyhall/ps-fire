# Completely inspired by: http://fabiensanglard.net/doom_fire_psx/

$width = $Host.UI.RawUI.WindowSize.Width
$height = $Host.UI.RawUI.WindowSize.Height
$bottomRow = $height - 1

$oldTemp = 0
If (($args[0] -le 7) -and ($args[0] -ge 0)) {
	$temp = $args[0]
} Else {
	$temp = 7
}

$pallet = " ",
          "`e[38;5;196m.",
          "`e[38;5;202m:",
          "`e[38;5;208m;",
          "`e[38;5;214m|",
          "`e[38;5;220mM",
          "`e[38;5;226mM",
          "`e[38;5;15m#"

Write-Host "`e[?25l"
Write-Host -NoNewline "`e[2J"

## initialise
$state = New-Object int[] ($width * $height)
$stateDoubleBuffer = New-Object int[] ($width * $height)

$j = $height * $width
$i = $j - $width
While ($i -lt $j) {
	$state[$i] = $temp
	$i++
}

$j = $height - 1
$y = 0
While ($y -lt $j) {
	$x = 0
	While ($x -lt $width) {
		$i = $y * $width + $x
		$state[$i] = 0
		$x++
	}
	$y++
}


# draw the initial bottom line (all hottest)

$x = 0
Write-Host -NoNewline "`e[${height};0H"
While ($x -lt $width) {
	Write-Host -NoNewline $pallet[$temp]
	$x++
}

# run
Try {
	$lastFrameDrawn = Get-Date
	While ($true) {
		$frame = ""
		$x = 0
		While ($x -lt $width) {
			$y = $height - 1
			While ($y -ge 1) {
				$i = $y * $width + $x

				# spread fire to weighted random row above
				$rand = (Get-Random -Maximum 5) -band 3
				$j = $i - $width * $rand
				# boundary check
				If ($j -ge 0 ) {
					# decay by a weighted random amount
					$randDecay = $rand -band 1
					$state[$j] = $state[$i] - $randDecay

					# boundary check
					If ($state[$j] -lt 0) {
						$state[$j] = 0
					}
				}

				If ($y -lt $bottomRow) {
					If ($stateDoubleBuffer[$i] -ne $state[$i]) {
						$yAnsiOffset = $y + 1
						$xAnsiOffset = $x + 1
						$frame += "`e[${yAnsiOffset};${xAnsiOffset}H"
						$frame += "$($pallet[$state[$i]])"
					}
				}

				$stateDoubleBuffer[$i] = $state[$i]
				$y--
			}

			$x++
		}

		# draw frame line to console
		Write-Host -NoNewline $frame
		$thisFrameDrawn = Get-Date

		# approximate target FPS
	    $frameDrawTime = [Math]::Round(($thisFrameDrawn - $lastFrameDrawn).TotalMilliseconds, 0)
	    Write-Host "`e[1;1H`e[38;5;106m${frameDrawTime}ms  "

	    $lastFrameDrawn = $thisFrameDrawn
	    $sleepTime = 100 - $frameDrawTime
	    If ($sleepTime -gt 0) {
	        Start-Sleep -Milliseconds $sleepTime
		}
	}
} Finally {
	Clear-Host
}