md Server\RedirectServer\Win32\Debug
md Server\RedirectServer\Win32\Release
md Server\RedirectServer\Win32\Test

md Server\RedirectServer\Win64\Debug
md Server\RedirectServer\Win64\Release
md Server\RedirectServer\Win64\Test

md Tests\Server\RedirectServer\Win32\Debug
md Tests\Server\RedirectServer\Win32\Release
md Tests\Server\RedirectServer\Win32\Test

md Tests\Client\Win32\Debug
md Tests\Client\Win32\Release
md Tests\Client\Win32\Test

xcopy redist\Server\RedirectServer\*.* Server\RedirectServer\Win32\Debug /E /F /Y
xcopy redist\Server\RedirectServer\*.* Server\RedirectServer\Win32\Release /E /F /Y
xcopy redist\Server\RedirectServer\*.* Server\RedirectServer\Win32\Test /E /F /Y

xcopy redist\Server\RedirectServer\*.* Server\RedirectServer\Win64\Debug /E /F /Y
xcopy redist\Server\RedirectServer\*.* Server\RedirectServer\Win64\Release /E /F /Y
xcopy redist\Server\RedirectServer\*.* Server\RedirectServer\Win64\Test /E /F /Y

xcopy redist\Server\RedirectServer\*.* Tests\Server\RedirectServer\Win32\Debug /E /F /Y
xcopy redist\Server\RedirectServer\*.* Tests\Server\RedirectServer\Win32\Release /E /F /Y
xcopy redist\Server\RedirectServer\*.* Tests\Server\RedirectServer\Win32\Test /E /F /Y



md Server\ControlServer\Win32\Debug
md Server\ControlServer\Win32\Release
md Server\ControlServer\Win32\Test

md Server\ControlServer\Win64\Debug
md Server\ControlServer\Win64\Release
md Server\ControlServer\Win64\Test

xcopy redist\Server\ControlServer\*.* Server\ControlServer\Win32\Debug /E /F /Y
xcopy redist\Server\ControlServer\*.* Server\ControlServer\Win32\Release /E /F /Y
xcopy redist\Server\ControlServer\*.* Server\ControlServer\Win32\Test /E /F /Y

xcopy redist\Server\ControlServer\*.* Server\ControlServer\Win64\Debug /E /F /Y
xcopy redist\Server\ControlServer\*.* Server\ControlServer\Win64\Release /E /F /Y
xcopy redist\Server\ControlServer\*.* Server\ControlServer\Win64\Test /E /F /Y

