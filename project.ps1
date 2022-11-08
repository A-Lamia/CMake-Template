param(
  [string]$Action,
  [string]$Type,
  [switch]$Run
)

$mode = @{ 
  'd' = 'debug';
  'rd' = 'release-debug';
  'r' = 'release';
  'rm' = 'release-mini';
}


function Get-Settings()
{
  $settings = Get-Content .\ProjectConfig.json -Raw | ConvertFrom-Json
  return $settings
}

# [TODO]: Write a function that dettects levels of directories and creates them.

function Get-Dir($path, $folder)
{
  $dir = Get-ChildItem $path -Directory 
  if ($dir.Name -eq $folder)
  {
    return $true 
  }
  return $false
}


function Initialize-Project()
{
  $settings = Get-Settings
  $output_dir = $settings.output
  if (Get-Dir "./" $output_dir)
  {
    Write-Host "Build directory already exsists."
  } else
  {
    New-Item -Path .\ -Name $output_dir -ItemType Directory 
    New-Item -Path .\build -Name "Debug" -ItemType Directory
    New-Item -Path .\build -Name "Release" -ItemType Directory 
  }
}

function Redo-Project()
{
  $settings = Get-Settings
  $output_dir = $settings.output.split("./")
  $dir = Get-ChildItem ".\" -Directory 
  if ($dir.Name -eq $output_dir)
  {
    Remove-Item -Path .\build -Force -Recurse
    Initialize-Project
  } else
  {
    Write-Host "Nothing to Reset."
  }
}


function New-Project($Type)
{
  if(!( Get-Dir "./" "build" ))
  {
    New-Item -Path .\ -Name "build" -ItemType Directory 
  } 
  
  $settings = Get-Settings  
  $source_dir = $settings.source
  $output_dir = $settings.output
  # $c_compiler = ($settings.c_compiler -ne "") ? "-D"
  # $cxx_compiler = $settings.cxx_compiler
  # $linker = $settings.linker
  $genorator = ($settings.genorator -ne "" ) ? "-G " + $settings.genorator : ""
  
  $command 
  switch ($Type.ToLower())
  {
    $mode['d']  
    {
      $folder = "Debug"
      if (!( Get-Dir "./build" $folder ))
      {
        New-Item -Path ./build -Name $folder -ItemType Directory 
      }
      
      $command = "cmake $genorator -S $source_dir -B $output_dir/$folder"
      Invoke-Expression $command
    }
    
    $mode['rd']
    {
      $folder = "Release_Debug"
      if (!(Get-Dir "./build" $folder))
      {
        Write-Host "Did i run?"
        New-Item -Path ./build -Name $folder -ItemType Directory 
      }
      
      $command = "cmake $genorator -DCMAKE_BUILD_TYPE='RelWIthDebInfo' -S $source_dir -B $output_dir/$folder"
      Invoke-Expression $command
    }
    
    $mode['r']
    {
      $folder = "Release"
      if (!(Get-Dir "./build" $folder))
      {
        New-Item -Path ./build -Name $folder -ItemType Directory 
      }
      
      $command = "cmake $genorator -DCMAKE_BUILD_TYPE='Release' -S $source_dir -B $output_dir/$folder"
      Invoke-Expression $command
    }
    $mode['rm']
    {
      $folder = "Release_Mini"
      if (!(Get-Dir "./build" $folder))
      {
        New-Item -Path ./build -Name $folder -ItemType Directory 
      }
      
      $command = "cmake $genorator -DCMAKE_BUILD_TYPE='MinSizeRel' -S $source_dir -B $output_dir/$folder"
      Invoke-Expression $command
    }
  } 
}


function Build-Project($Type,$Run)
{
  $command
  switch ($Type.ToLower())
  {
    $mode['d']
    {
      $command = "cmake --build ./build/Debug" 
      Invoke-Expression $command
      if ($Run)
      {
        Open-Executable($mode['d'])
      }
    }
    $mode['rd']
    {
      $command = "cmake --build ./build/Release_Debug" 
      Invoke-Expression $command
      if ($Run)
      {
        Open-Executable($mode['rd'])
      }
    }   
    $mode['r']
    {
      $command = "cmake --build ./build/Release" 
      Invoke-Expression $command
      if ($Run)
      {
        Open-Executable($mode['r'])
      }
    }    
    $mode['rm']
    {
      $command = "cmake --build ./build/Release_Mini" 
      Invoke-Expression $command
      if ($Run)
      {
        Open-Executable($mode['rm'])
      }
    }
  }  
}


function Open-Executable($Type)
{
  if (!(Get-Dir "./" "build"))
  {
    Write-Host "No build directory was found."
    return
  }
  $settings = Get-Settings
  $name = $settings.exe_name
  switch ($Type.ToLower())
  {
    $mode['d']
    {
      $command = "./build/Debug/$name.exe"     
      Invoke-Expression $command
    }
    $mode['rd']
    {
      $command = "./build/Release_Debug/$name.exe"     
      Invoke-Expression $command
    }
    $mode['r']
    {
      $command = "./build/Release/$name.exe"     
      Invoke-Expression $command
    }
    $mode['rm']
    {
      $command = "./build/Release_Mini/$name.exe"     
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
  "reset"
  {
    Redo-Project
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
