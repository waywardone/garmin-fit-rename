# Links to original information that led to this script:
# https://forums.garmin.com/apps-software/mac-windows-software/f/garmin-express-windows/81739/change-file-name-format
# https://www.dropbox.com/s/16frs902kz17uzg/copy-garmin-fit-files-2018-01-05.bash?dl=0

param (
    [Parameter(Mandatory=$True)]
    [string] $SRCDIR
)

function sanityCheck
{
    if ( [string]::IsNullOrEmpty($SRCDIR) )
    {
        Write-Host "Source directory for Garmin FIT files not specified!" -Foregroundcolor Red -Backgroundcolor Black
        exit
    }

    if ( ! ( Test-Path -path $SRCDIR ) )
    {
        Write-Host "$SRCDIR doesn't exist. Specify a valid SRCDIR for Garmin FIT files." -Foregroundcolor Red -Backgroundcolor Black
        exit
    }
}

function convertFromBase36
{
    param (
        [parameter(Mandatory=$True, HelpMessage="Alphadecimal string to convert")]
        [string]$base36Num = ""
    )
    
    $alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"
    $inputarray = $base36Num.tolower().tochararray()
    [array]::reverse($inputarray)
    [long]$decNum = 0
    $pos = 0

    foreach ($c in $inputarray)
    {
        $decNum += $alphabet.IndexOf($c) * [long][Math]::Pow(36, $pos)
        $pos++
    }
    $decNum
}

function FR645
{
    param (
        [Parameter(Mandatory=$True)]
        [string] $name = ""
    )
    
    $NEWNAME = $name -replace "(\d+)-(\d+)-(\d+)-(\d+)-(\d+)-(\d+)\.[a-zA-Z]*",'$1$2$3-$4$5$6.fit'
    return $NEWNAME
}

function FR235
{
    param(
        [Parameter(Mandatory=$True)]
        [string] $name
    )

    $GCHARMAP = @{
        '0' = 0;    '1' = 1;    '2' = 2;    '3' = 3;
        '4' = 4;    '5' = 5;    '6' = 6;    '7' = 7;
        '8' = 8;    '9' = 9;    'A' = 10;    'B' = 11;
        'C' = 12;    'D' = 13;    'E' = 14;    'F' = 15;
        'G' = 16;    'H' = 17;    'I' = 18;    'J' = 19;
        'K' = 20;    'L' = 21;    'M' = 22;    'N' = 23;
        'O' = 24;    'P' = 25;    'Q' = 26;    'R' = 27;
        'S' = 28;    'T' = 29;    'U' = 30;    'V' = 31;
        'W' = 32;    'X' = 33;    'Y' = 34;    'Z' = 35;
      }

    $CENTURY = get-date -UFormat %C
    $NEWNAME = "$CENTURY"
    $n = 0
    while($n -lt 8) {
        $GCHAR = $name.SubString($n,1)
        $NCHAR = $GCHARMAP.$GCHAR

        if ( $n -eq 3 ) {
            $NEWNAME = $NEWNAME + '-'
        }

        if ( $n -eq 0 -and $NCHAR -lt 10 ) {
            $NEWNAME = $NEWNAME + "1$NCHAR"
        } elseif ( $n -eq 0 -and $NCHAR -ge 10 ) {
            $NEWNAME = $NEWNAME + "2" + $NCHAR%10
        } elseif ( ($n -eq 1 -or $n -eq 2 -or $n -eq 3) -and $NCHAR -lt 10 ) {
            $NEWNAME = $NEWNAME + "0$NCHAR"
        } elseif ( $n -eq 4 -or $n -eq 5 -or $n -eq 6 -or $n -eq 7 ) {
            $NEWNAME = $NEWNAME + $GCHAR
        } else {
            $NEWNAME = $NEWNAME + $NCHAR
        }
        $n = $n + 1
    }
    $NEWNAME = $NEWNAME + '-' + $name.SubString(0,8) + '.fit'
    return $NEWNAME
}

$CURRUSER = [Environment]::UserName
$DESKTOP = "C:\Users\$CURRUSER\Desktop"

$TSTAMP = get-date -f yyyyMMdd-HHmmss
$DESTDIR = "$DESKTOP\$TSTAMP-Garmin"

sanityCheck

if(!(Test-Path -Path $DESTDIR )){
  New-Item -Force -ItemType directory -Path $DESTDIR
}

$files = Get-ChildItem -Path $SRCDIR -Recurse -Include *.fit,*.FIT

foreach ($f in $files) {
    $file = Get-Item $f
    $fext = $file.Extension
    $fname = $file.Name

    if ($fname -match "\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}\.fit") {
        # Example: 2019-09-01-06-40-57.fit
        $NEWNAME = FR645($fname)
    } elseif ($fname -match "[0-9A-Z]{1}[1-9ABC]{1}[1-9A-V]{1}[1-9A-N]{1}[\d]{4}") {
        # Example: 96FG1906.FIT
        $NEWNAME = FR235($fname)
    } else {
        Write-Host "Don't know how to process $f" -Foregroundcolor Red -Backgroundcolor Black
        continue
    }
    
    $Y = $NEWNAME.SubString(0,4)
    if(!(Test-Path -Path $DESTDIR\$Y )){
        New-Item -Force -ItemType directory -Path $DESTDIR\$Y
    }
    Write-Host "Renaming " $fname "to " $NEWNAME
    Copy-Item -Path $f -Destination $DESTDIR\$Y\$NEWNAME
}
