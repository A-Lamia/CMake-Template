param(
  [string]$Action,
  [string]$Type,
  [switch]$Run
)


function Get-Settings()
{
  $settings = Get-Content .\ProjectConfig.json -Raw | ConvertFrom-Json
  return $settings
}


function Set-Settings($overide = $false)
{
  if (( $null -eq $Global:settings ) -or ( $overide -eq $true ))
  {
    $json = (Get-Content .\ProjectConfig.json -Raw | ConvertFrom-Json) 
  
    $Global:settings = @{
      'output' = $json.output.replace("\", "/").replace(" ", "_");  
      'source' = $json.source.replace("\", "/").replace(" ", "' '");
      'c_version' = $json.c_version;
      'cxx_version' = $json.cxx_version;
      'c_compiler' = $json.c_compiler.replace("\", "/").replace(" ", "' '");
      'cxx_compiler' = $json.cxx_compiler.replace("\", "/").replace(" ", "' '");
      'linker' = $json.linker.replace("\", "/").replace(" ", "' '");
      'genorator' = $json.genorator;
      'exe_name' = $json.exe_name;
      'CPM_CACHE' = $json.CPM_CACHE.replace("\", "/").replace(" ", "' '")
    }
    
    Write-Output $Global:settings
    if($Global:settings.CPM_CACHE -ne "")
    {
      $env:CPM_CACHE = $settings.CPM_CACHE
    }
  }
}

Set-Settings

$mode = @{ 
  'd' = 'debug';
  'rd' = 'release-debug';
  'r' = 'release';
  'rm' = 'release-mini';
}


function Get-Dir($path, $folder)
{
  if (Test-Path $output)
  {
    $dir = Get-ChildItem $path -Directory 
    if ($dir.Name -eq $folder)
    {
      return $true 
    }
  }
  return $false
}


function New-OutputDir()
{
  $output = $Global:Settings.output
  
  if(Get-Dir ".\", $output)
  {
    $routput = $output
    New-Item $routput -ItemType Directory 
  }
}


function Initialize-Project()
{
  Set-Settings $true
}


function Redo-Project($Type)
{
  $output = $Global:Settings.output
  
  switch ($Type.ToLower())
  {
    "project"
    {
      $command = "Remove-Item $output/*"
      Invoke-Expression $command
    }
    $mode["d"]
    {
      $command = "Remove-Item $output/Debug/*"
      Invoke-Expression $command
    }
    $mode["rd"]
    {
      $command = "Remove-Item $output/Release_Debug/*"
      Invoke-Expression $command
    }
    $mode["r"]
    {
      $command = "Remove-Item $output/Release/*"
      Invoke-Expression $command
    }
    $mode["rm"]
    {
      $command = "Remove-Item $output/Release_Mini/*"
      Invoke-Expression $command
    }
  }  
}


function New-Project($Type)
{
  $source_dir = $Global:settings.source
  $output = $Global:Settings.output
  
  $c_compiler = ($Global:settings.c_compiler -ne "") ? "-DCMAKE_C_COMPILER="+$Global:settings.c_compiler : ""
  $cxx_compiler = ($Global:settings.cxx_compiler -ne "") ? "-DCMAKE_CXX_COMPILER="+$Global:settings.cxx_compiler : ""
  $linker = ( $Global:settings.linker -ne "" ) ? "-DCMAKE_LINKER="+$Global:settings.linker : ""
  $tools = "$c_compiler $cxx_compiler $linker"
  
  $c_version = ($Global:settings.c_version -ne "") ? "-DCMAKE_C_STANDARD"+$Global:settings.c_version : "" 
  $cxx_version = ($Global:settings.cxx_version -ne "") ? "-DCMAKE_CXX_STANDARD"+$Global:settings.cxx_version : "" 
  $version = "$c_version $cxx_version"
  
  $genorator = ($settings.genorator -ne "" ) ? "-G " + $settings.genorator : ""
  
  $command 
  switch ($Type.ToLower())
  {
    $mode['d']  
    {
      $folder = "Debug"
      if (!( Get-Dir $output $folder ))
      {
        New-Item -Path "$output/$folder"  -ItemType Directory 
      }
      
      $command = "cmake $genorator -S $source_dir -B $output/$folder $tools $version"
      Invoke-Expression $command
    }
    
    $mode['rd']
    {
      $folder = "Release_Debug"
      if (!(Get-Dir $output $folder))
      {
        Write-Host "Did i run?"
        New-Item -Path "$output/$folder"  -ItemType Directory 
      }
      
      $command = "cmake $genorator -DCMAKE_BUILD_TYPE='RelWIthDebInfo' -S $source_dir -B $output/$folder $tools $version"
      Invoke-Expression $command
    }
    
    $mode['r']
    {
      $folder = "Release"
      if (!(Get-Dir $output $folder))
      {
        New-Item -Path "$output/$folder"  -ItemType Directory 
      }
      
      $command = "cmake $genorator -DCMAKE_BUILD_TYPE='Release' -S $source_dir -B $output/$folder $tools $version"
      Invoke-Expression $command
    }
    $mode['rm']
    {
      $folder = "Release_Mini"
      if (!(Get-Dir $output $folder))
      {
        New-Item -Path "$output/$folder"  -ItemType Directory 
      }
      
      $command = "cmake $genorator -DCMAKE_BUILD_TYPE='MinSizeRel' -S $source_dir -B $output/$folder $tools $version"
      Invoke-Expression $command
    }
  } 
}


function Build-Project($Type,$Run)
{
  $output = $Global:Settings.output 
  switch ($Type.ToLower())
  {
    $mode['d']
    {
      $command = "cmake --build $output/Debug" 
      Invoke-Expression $command
      if ($Run)
      {
        Open-Executable $mode['d'] 
      }
    }
    $mode['rd']
    {
      $command = "cmake --build ./build/Release_Debug" 
      Invoke-Expression $command
      if ($Run)
      {
        Open-Executable $mode['rd'] 
      }
    }   
    $mode['r']
    {
      $command = "cmake --build ./build/Release" 
      Invoke-Expression $command
      if ($Run)
      {
        Open-Executable $mode['r'] 
      }
    }    
    $mode['rm']
    {
      $command = "cmake --build ./build/Release_Mini" 
      Invoke-Expression $command
      if ($Run)
      {
        Open-Executable $mode['rm']
      }
    }
  }  
}


function Open-Executable($Type)
{
  function Get-Path($dir)
  {
    $name = $Global:settings.exe_name
    $build_dir = $Global:settings.output + "/$dir"
    $path = "$build_dir/$name"

    if(Test-Path $path)
    {
      return $path
    } else
    {
      $files = Get-ChildItem -Path $build_dir -Recurse
      foreach($file in $files)
      {
        if($file.Name -Match "$name$")
        {
          return $file
        }
      }
    }
    return "Write-Host 'Executable could not be found'"
  }
  
  switch ($Type.ToLower())
  {
    $mode['d']
    {
      $command = Get-Path "Debug"     
      Invoke-Expression $command
    }
    $mode['rd']
    {
      $command = Get-Path "Release-Debug"     
      Invoke-Expression $command
    }
    $mode['r']
    {
      $command = Get-Path "Release"     
      Invoke-Expression $command
    }
    $mode['rm']
    {
      $command = Get-Path "Release-Mini"     
      Invoke-Expression $command
    }
      
  } 


}


switch ($Action.ToLower())
{
  "init"
  {
    Initialize-Project 
  }
  "clean"
  {
    Redo-Project $Type
  }
  "create"
  {
    New-Project $Type
  }
  "build"
  {
    Build-Project $Type $Run
  }
  "run"
  {
    Open-Executable $Type
  }
}
