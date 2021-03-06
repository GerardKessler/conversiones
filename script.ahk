hks := array()
hks[1] := ["f4", "fileConverter", "Convertir el archivo con el foco"]
hks[2] := ["+f4", "folderConverter", "convierte todos los archivos de la carpeta actual"]
hks[3] := ["!^s", "suspend", "Suspende y reanuda el script"]
hks[4] := ["!^q", "exit", "Cierra el script"]

soundPlay files\start.mp3

#include files\gui.ahk
#include files\hotkeys.ahk
#include files\speak.ahk

IfNotExist, files\cuality.ini
	iniWrite, 128, files\cuality.ini, audio_bitrate, value
else
	iniRead, bitrate, files\cuality.ini, audio_bitrate, value

menu, tray, noStandard
menu, tray, tip, Conversiones
menu, tray, add, Lista de comandos, commands
menu, tray, add
menu, bitrate, add, 128, audio_bitrate
menu, bitrate, add, 192, audio_bitrate
menu, bitrate, add, 256, audio_bitrate
menu, bitrate, add, 320, audio_bitrate
menu, tray, add,% "Audio_bitrate. El valor actual es " bitrate " kbps. ", :bitrate
menu, tray, add, Instrucciones, readme
menu, tray, add, Suspender el script, suspend
menu, tray, add, Cerrar el script, exit

menu, conversiones, add
menu, audio, add, mp3, audio_video
menu, audio, add, flac, audio_video
menu, audio, add, OGG, audio_video
menu, audio, add, m4a, audio_video
menu, audio, add, wav, audio_video
menu, audio, add, o&tros, otros
menu, conversiones, add, audio, :audio

menu, conversiones, add
menu, video, add, mp4, audio_video
menu, video, add, avi, audio_video
menu, video, add, mpg, audio_video
menu, video, add, flv, audio_video
menu, video, add, mkv, audio_video
menu, video, add, o&tros, otros
menu, conversiones, add, video, :video

menu, conversiones, add
menu, documento, add, txt, documento
menu, documento, add, html, documento
menu, documento, add, md, documento
menu, documento, add, rtf, documento
menu, documento, add, epub, documento
menu, documento, add, o&tros, otros
menu, conversiones, add, documento, :documento
return

audio_bitrate:
	iniWrite, %a_thisMenuItem%, files\cuality.ini, audio_bitrate, value	
	reload

fileConverter:
	SoundPlay C:\Windows\Media\Windows Exclamation.wav
	filePath := getFilePath()
menu, conversiones, show
return

folderConverter:
folderPath := getPath()
gui, add, text,, Seleccione el formato del archivo
gui, add, listBox, vFileFormat, mp3||flac|m4a|ogg|wav|wma|mp4|avi|flv|mov|mkv
gui, add, button, gConversion, iniciar la conversión
gui, add, button, gCloseGui, Cancelar
gui, show,, conversiones
return

conversion() {
	global folderPath, fileFormat, bitrate
	gui, submit, hide
	sleep 100
	message("conversión iniciada")
	loop, files, %folderPath%\*.*, R
	{
		splitPath, a_loopFileFullPath, fileName, dirName, extensionName, name, outDrive
		runWait cmd.exe /c %a_workingDir%\files\ffmpeg.exe -i "%a_loopFileFullPath%" -b:a %bitrate%000 "%dirName%\%name%.%fileFormat%",, hide
		message(fileName)
	}
	soundPlay files\finish.mp3
	gui, destroy
}

closeGui() {
	gui, destroy
}

audio_video(itemName) {
	global filePath, bitrate
	sleep 100
	mute()
	SplitPath, filePath, fileName, dirName, extensionName, name, outDrive
	if (extensionName = itemName) {
		sleep 100
		msgBox, 0, Proceso cancelado;, No se puede convertir %fileName% en %itemName%. Los formatos de entrada y de salida son idénticos.
		return
	}
	sleep 75
	mute()
	message("convirtiendo " fileName " a " itemName)
	command = %a_workingDir%\files\ffmpeg.exe -i "%filePath%" -b:a %bitrate%000 "%dirName%\%name%.%itemName%"
	runWait cmd.exe /c %command%,, hide
	soundPlay files\finish.mp3
	message("conversión finalizada")
}

documento(itemName) {
	global filePath
	SplitPath, filePath, fileName, dirName, extensionName, name, outDrive
	if (extensionName = itemName) {
		sleep 100
		msgBox, 0, Proceso cancelado;, No se puede convertir %fileName% en %itemName%. Los formatos de entrada y de salida son idénticos.
		return
	}
	sleep 75
	mute()
	message("convirtiendo " fileName " a " itemName)
	command = %a_workingDir%\files\pandoc.exe -o "%dirName%\%name%.%itemName%" "%filePath%"
	runWait cmd.exe /c %command%,, hide
	soundPlay files\finish.mp3
	message("conversión finalizada")
}

otros(itemName, itemPos, menuName) {
	global filePath, bitrate
	SplitPath, filePath, fileName, dirName, extensionName, name, outDrive
	sleep 50
	inputBox, extension, Por favor ingresa la extensión a convertir sin el punto
	if menuName = "documento"
		command = %a_workingDir%\files\pandoc.exe -o "%dirName%\%name%.%extension%" "%filePath%"
	else if (menuName="audio" or menuName="video")
		command = %a_workingDir%\files\ffmpeg.exe -i "%filePath%" -b:a %bitrate%000 "%dirName%\%name%.%extension%"
	runWait cmd.exe /c %command%,, hide
	soundPlay files\finish.mp3
}

getPath() {
	explorerHwnd := WinActive("ahk_class CabinetWClass")
	if (explorerHwnd)
	{
		for window in ComObjCreate("Shell.Application").Windows
		{
			if (window.hwnd==explorerHwnd)
			{
				return window.Document.Folder.Self.Path
			}
		}
	}
}

getFilePath() {
	WinGetClass, winClass, % "ahk_id" . hWnd := WinExist("A")
	if !(winClass ~= "(Cabinet|Explore)WClass")
		Return
	for window in ComObjCreate("Shell.Application").Windows
		if (hWnd = window.HWND) && (oShellFolderView := window.document)
			break
	for item in oShellFolderView.SelectedItems
		result .= (result = "" ? "" : "`n") . item.path
	if !result
		result := oShellFolderView.Folder.Self.Path
	Return result
}

+f1::
commands()
return

ListGuiEscape:
gui, list:destroy
return

readme:
	run files\readme.html
	return

suspend() {
static t
suspend
	menu, tray, toggleCheck, Suspender el script
	message((a_isSuspended)? "Script suspendido" : "Script reactivado")
}

exit:
message("script finalizado")
exitapp