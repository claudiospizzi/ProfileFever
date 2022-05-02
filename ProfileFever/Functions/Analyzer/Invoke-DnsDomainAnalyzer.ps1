<#
    .SYNOPSIS
        Analyze a DNS domain.

    .DESCRIPTION
        This function will analyze a DNS domain and return a list of relevant
        records around the domain itself, mail service and other relevant
        services.

    .EXAMPLE
        PS C:\> Invoke-DnsDomainAnalyzer -Domain 'microsoft.com'
        Analyze the domain microsoft.com.
#>
function Invoke-DnsDomainAnalyzer
{
    [CmdletBinding()]
    param
    (
        # The DNS domain name.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [System.String[]]
        $DomainName,

        # The DNS resolver to query. If not specified, the default is used.
        [Parameter(Mandatory = $false)]
        [System.String]
        $DnsServer
    )

    process
    {
        $dnsQuerySplat = @{
            ErrorAction = 'SilentlyContinue'
        }
        if ($PSBoundParameters.ContainsKey('DnsServer'))
        {
            $dnsQuerySplat['Server'] = $PSBoundParameters['DnsServer']
        }

        $headerSplat = @{
            ForegroundColor = 'Cyan'
        }

        foreach ($domain in $DomainName)
        {
            try
            {
                ##
                ## PART 1: DOMAIN
                ##

                Write-Host @headerSplat "`nDomain`n******"

                # Start of Authority record (SOA)
                Resolve-DnsName @DnsQuerySplat -Name $domain -Type 'SOA' |
                    Where-Object { $_.Type -eq 'SOA' } |
                        ForEach-Object {
                            [PSCustomObject] @{
                                PSTypeName    = 'ProfileFever.Analyzer.Domain.StartOfAuthority'
                                Name          = $_.Name
                                Type          = $_.Type
                                TTL           = $_.TTL
                                SerialNumber  = $_.SerialNumber
                                DefaultTTL    = $_.DefaultTTL
                                Administrator = $_.Administrator
                            }
                        } | Format-Table

                # The domain name servers.
                Resolve-DnsName @DnsQuerySplat -Name $domain -Type 'NS' |
                    Where-Object { $_.Type -eq 'NS' } |
                        ForEach-Object {
                            $nameServerIP4 = Resolve-DnsName @DnsQuerySplat -Name $_.NameHost -Type 'A' |
                                                 Where-Object { $_.Type -eq 'A' }
                            $nameServerIP6 = Resolve-DnsName @DnsQuerySplat -Name $_.NameHost -Type 'AAAA' |
                                                 Where-Object { $_.Type -eq 'AAAA' }
                            [PSCustomObject] @{
                                PSTypeName = 'ProfileFever.Analyzer.Domain.NameServer'
                                Name       = $_.NameHost
                                Type       = $_.Type
                                TTL        = $_.TTL
                                IP4Address = $nameServerIP4.IP4Address
                                IP6Address = $nameServerIP6.IP6Address
                            }
                        } | Format-Table

                # If the domain is signed with DNSSEC, show the records
                Resolve-DnsName @DnsQuerySplat -Name $domain -Type 'DNSKEY' |
                    Where-Object { $_.Type -eq 'DNSKEY' -and $_.Protocol -eq 'DNSSEC' } |
                        ForEach-Object {
                            [PSCustomObject] @{
                                PSTypeName = 'ProfileFever.Analyzer.Domain.DnsSecurityExtension'
                                Name       = $_.Name
                                Type       = $_.Type
                                TTL        = $_.TTL
                                Protocol   = $_.Protocol
                                Algorithm  = $_.Algorithm
                                Key        = [System.Convert]::ToBase64String($_.Key)
                            }
                        } | Format-Table


                ##
                ## PART 2: MAIL SERVICE
                ##

                Write-Host @headerSplat "`nMail Service`n************"

                # MX record for the mail servers
                Resolve-DnsName @DnsQuerySplat -Name $domain -Type 'MX' |
                    Where-Object { $_.Type -eq 'MX' } |
                        Sort-Object -Property 'Preference' |
                            ForEach-Object {
                                [PSCustomObject] @{
                                    PSTypeName = 'ProfileFever.Analyzer.Domain.MailExchanger'
                                    Name       = $_.Exchange
                                    Type       = $_.Type
                                    TTL        = $_.TTL
                                    Preference = $_.Preference
                                }
                            } | Format-Table

                # The mail server autodiscovery records for Microsoft Exchange
                Resolve-DnsName @DnsQuerySplat -Name "_autodiscover._tcp.$domain" -Type 'SRV' |
                    Where-Object { $_.Type -eq 'SRV' } |
                        ForEach-Object {
                            [PSCustomObject] @{
                                PSTypeName    = 'ProfileFever.Analyzer.Domain.Generic'
                                Name          = $_.Name
                                Type          = $_.Type
                                TTL           = $_.TTL
                                NameHost      = $_.NameHost
                                IP4Address    = $_.IP4Address
                                IP6Address    = $_.IP6Address
                                ServiceTarget = $(if ($_.Type -eq 'SRV') { '{0}:{1}' -f $_.NameTarget, $_.Port } else { $null })
                            }
                        } | Format-Table
                Resolve-DnsName @DnsQuerySplat -Name "autodiscover.$domain" |
                    ForEach-Object {
                        [PSCustomObject] @{
                            PSTypeName    = 'ProfileFever.Analyzer.Domain.Generic'
                            Name          = $_.Name
                            Type          = $_.Type
                            TTL           = $_.TTL
                            NameHost      = $_.NameHost
                            IP4Address    = $_.IP4Address
                            IP6Address    = $_.IP6Address
                            ServiceTarget = $(if ($_.Type -eq 'SRV') { '{0}:{1}' -f $_.NameTarget, $_.Port } else { $null })
                        }
                    } | Format-Table

                # The Mail Service SPF records
                Resolve-DnsName @DnsQuerySplat -Name $domain -Type 'TXT' |
                    Where-Object { $_.Type -eq 'TXT' -and $_.Strings[0] -like 'v=spf1 *' } |
                        ForEach-Object {
                            $record = $_
                            $_.Strings | ForEach-Object { $_ -split ' ' } |
                                    Where-Object { $_ -ne '' -and $_ -ne 'v=spf1' } |
                                        ForEach-Object {
                                            [PSCustomObject] @{
                                                PSTypeName = 'ProfileFever.Analyzer.Domain.SenderPolicyFramework'
                                                Name       = $_
                                                Type       = 'TXT'
                                                TTL        = $record.TTL
                                                ValueType  = 'v=spf1'
                                            }
                                        }
                            } | Format-Table

                # The Mail Service DMARC records
                Resolve-DnsName @DnsQuerySplat -Name "_dmarc.$domain" -Type 'TXT' |
                    Where-Object { $_.Type -eq 'TXT' -and $_.Strings[0] -like 'v=DMARC1*' } |
                        ForEach-Object {
                            [PSCustomObject] @{
                                PSTypeName = 'ProfileFever.Analyzer.Domain.DomainMessageAuthenticationReportingConformance'
                                Name       = $_.Name
                                Type       = $_.Type
                                TTL        = $_.TTL
                                ValueType  = $(try { $_.Strings[0].Split(';', 2)[0].Trim() } catch { '' })
                                Definition = $(try { $_.Strings[0].Split(';', 2)[1].Trim() } catch { $_.Strings[0] })
                            }
                        }


                ##
                ## PART 3: ENTERPRISE MOBILITY
                ##

                Write-Host @headerSplat "`nMobility & Security`n*******************"

                "enterpriseregistration.$domain", "enterpriseenrollment.$domain" |
                    ForEach-Object { Resolve-DnsName @DnsQuerySplat -Name $_  } |
                        ForEach-Object {
                            [PSCustomObject] @{
                                PSTypeName    = 'ProfileFever.Analyzer.Domain.Generic'
                                Name          = $_.Name
                                Type          = $_.Type
                                TTL           = $_.TTL
                                NameHost      = $_.NameHost
                                IP4Address    = $_.IP4Address
                                IP6Address    = $_.IP6Address
                                ServiceTarget = $(if ($_.Type -eq 'SRV') { '{0}:{1}' -f $_.NameTarget, $_.Port } else { $null })
                            }
                        } | Format-Table


                ##
                ## PART 4: SKYPE FOR BUSINESS
                ##

                Write-Host @headerSplat "`nSkype for Business`n******************"

                "_sip._tls.$domain", "_sipfederationtls._tcp.$domain" |
                    ForEach-Object { Resolve-DnsName @DnsQuerySplat -Name $_ -Type 'SRV' } |
                        Where-Object { $_.Type -eq 'SRV' } |
                            ForEach-Object {
                                [PSCustomObject] @{
                                    PSTypeName    = 'ProfileFever.Analyzer.Domain.Generic'
                                    Name          = $_.Name
                                    Type          = $_.Type
                                    TTL           = $_.TTL
                                    NameHost      = $_.NameHost
                                    IP4Address    = $_.IP4Address
                                    IP6Address    = $_.IP6Address
                                    ServiceTarget = $(if ($_.Type -eq 'SRV') { '{0}:{1}' -f $_.NameTarget, $_.Port } else { $null })
                                }
                            } | Format-Table

                "sip.$domain", "lyncdiscover.$domain" |
                    ForEach-Object { Resolve-DnsName @DnsQuerySplat -Name $_  } |
                        ForEach-Object {
                            [PSCustomObject] @{
                                PSTypeName    = 'ProfileFever.Analyzer.Domain.Generic'
                                Name          = $_.Name
                                Type          = $_.Type
                                TTL           = $_.TTL
                                NameHost      = $_.NameHost
                                IP4Address    = $_.IP4Address
                                IP6Address    = $_.IP6Address
                                ServiceTarget = $(if ($_.Type -eq 'SRV') { '{0}:{1}' -f $_.NameTarget, $_.Port } else { $null })
                            }
                        } | Format-Table
            }
            catch
            {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}
