#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Font symbols for easy use
################################################################################
typeset -gAH icons
icons=( # TODO Rename and remove unused
      LEFT_SEGMENT_SEPARATOR         $'\uE0B0'              # 
      RIGHT_SEGMENT_SEPARATOR        $'\uE0B2'              # 
      LEFT_SEGMENT_END_SEPARATOR     ' '                    # Whitespace
      LEFT_SUBSEGMENT_SEPARATOR      $'\uE0B1'              # 
      RIGHT_SUBSEGMENT_SEPARATOR     $'\uE0B3'              # 
      CARRIAGE_RETURN_ICON           $'\u21B5'              # ↵
      ROOT_ICON                      $'\uE614 '             # 
      RUBY_ICON                      $'\uF219 '             # 
      AMAZON_ICON                    $'\uF270'              # 
      AWS_EB_ICON                    $'\UF1BD  '            # 
      BACKGROUND_JOBS_ICON           $'\uF013 '             # 
      TEST_ICON                      $'\uF188'              # 
      TODO_ICON                      $'\uF133'              # 
      BATTERY_ICON                   $'\UF240 '             # 
      DISK_ICON                      $'\uF0A0'              # 
      OK_ICON                        $'\uF00C'              # 
      FAIL_ICON                      $'\uF00D'              # 
      SYMFONY_ICON                   $'\uE757'              # 
      NODE_ICON                      $'\uE617 '             # 
      MULTILINE_FIRST_PROMPT_PREFIX  $'\u256D'$'\U2500'     # ╭─
      MULTILINE_NEWLINE_PROMPT_PREFIX  $'\u251C'$'\U2500'   # ├─
      MULTILINE_LAST_PROMPT_PREFIX   $'\u2570'$'\U2500 '    # ╰─
      APPLE_ICON                     $'\uF179'              # 
      WINDOWS_ICON                   $'\uF17A'              # 
      FREEBSD_ICON                   $'\UF30E '             # 
      ANDROID_ICON                   $'\uF17B'              # 
      LINUX_ICON                     $'\uF17C'              # 
      SUNOS_ICON                     $'\uF185 '             # 
      HOME_ICON                      $'\uF015'              # 
      HOME_SUB_ICON                  $'\uF07C'              # 
      FOLDER_ICON                    $'\uF115'              # 
      NETWORK_ICON                   $'\uF1EB'              # 
      LOAD_ICON                      $'\uF080 '             # 
      SWAP_ICON                      $'\uF464'              # 
      RAM_ICON                       $'\uF0E4'              # 
      SERVER_ICON                    $'\uF0AE'              # 
      VCS_UNTRACKED_ICON             $'\uF059'              # 
      VCS_UNSTAGED_ICON              $'\uF06A'              # 
      VCS_STAGED_ICON                $'\uF055'              # 
      VCS_STASH_ICON                 $'\uF01C '             # 
      VCS_INCOMING_CHANGES_ICON      $'\uF01A '             # 
      VCS_OUTGOING_CHANGES_ICON      $'\uF01B '             # 
      VCS_TAG_ICON                   $'\uF02B '             # 
      VCS_BOOKMARK_ICON              $'\uF461 '             # 
      VCS_COMMIT_ICON                $'\uE729 '             # 
      VCS_BRANCH_ICON                $'\uF126 '             # 
      VCS_REMOTE_BRANCH_ICON         $'\uE728 '             # 
      VCS_GIT_ICON                   $'\uF113 '             # 
      VCS_GIT_GITHUB_ICON            $'\uE709 '             # 
      VCS_GIT_BITBUCKET_ICON         $'\uE703 '             # 
      VCS_GIT_GITLAB_ICON            $'\uF296 '             # 
      VCS_HG_ICON                    $'\uF0C3 '             # 
      VCS_SVN_ICON                   $'\uE72D '             # 
      RUST_ICON                      $'\uE7A8 '             # 
      PYTHON_ICON                    $'\UE73C '             # 
      SWIFT_ICON                     $'\uE755'              # 
      GO_ICON                        $'\uE626'              # 
      JAVA_ICON                      $'\uE738'              # 
      PUBLIC_IP_ICON                 $'\UF0AC'              # 
      LOCK_ICON                      $'\UF023'              # 
      EXECUTION_TIME_ICON            $'\uF252'              # 
      SSH_ICON                       $'\uF489'              # 
      VPN_ICON                       '(vpn)'
      KUBERNETES_ICON                $'\U2388'              # ⎈

      ################# Added #################
      LAPTOP_ICON                    $'\uF109'              # 
      AWS_ICON                       $'\uF375'              # 
      CLOUD_ICON                     $'\uF0C2'              # 
      BADGE_ICON                     $'\uF2C1'              # 
    )
################################################################################
