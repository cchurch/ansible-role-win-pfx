#!powershell
# (c) 2015, Michael Ingraham <mingraham@solarcity.com>, and others
# (c) 2017, Chris Church <cchurch@ansible.com>
#
# This file is (not yet) part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

$params = Parse-Args $args;

$path = Get-Attr $params "path" $FALSE
$state = Get-Attr $params "state" $FALSE
$password = Get-Attr $params "password" $FALSE

If ($path -eq $FALSE)
{
    Fail-Json (New-Object psobject) "missing required argument: path"
}
Else
{
    $result = New-Object psobject;
    $logfile = [IO.Path]::GetTempFileName();
    $securePwd= ""
    If ($password -ne $FALSE)
    {
         $securePwd = ConvertTo-SecureString -String "$password" -Force -AsPlainText
    }
    $thumbprintPresent = $FALSE;
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($path, $securePwd, 'PersistKeySet')
    $thumbprint = $cert.Thumbprint
    Set-Attr $result "thumbprint" $thumbprint;

    $remote_cert_locations = @("Cert:\LocalMachine\My")

    ForEach ($remote_cert_location in $remote_cert_locations)
    { 
        If (Get-ChildItem -Path $remote_cert_location | Where-Object {$_.Thumbprint -match "$thumbprint"})
        {
            $thumbprintPresent = $TRUE;
        }
    }

    If ($state -eq "absent" -and $thumbprintPresent -eq $TRUE)
    {
        ForEach ($remote_cert_location in $remote_cert_locations)
        {
            Remove-Item -Path $remote_cert_location\$thumbprint -DeleteKey
        }
        Set-Attr $result "changed" $true;
    }
    ElseIf ($state -eq "present" -and $thumbprintPresent -eq $FALSE)
    {
        ForEach ($remote_cert_location in $remote_cert_locations) 
        {
            If ($securePwd -ne "")
            {
                Import-PfxCertificate -FilePath $path -CertStoreLocation $remote_cert_location -Password $securePwd
            }
            Else
            {
                Import-PfxCertificate -FilePath $path -CertStoreLocation $remote_cert_location
            }
        }
        Set-Attr $result "changed" $true;
    }
}

$logcontents = Get-Content $logfile;
Remove-Item $logfile;

Set-Attr $result "log" $logcontents;

Exit-Json $result;
