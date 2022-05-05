#!/bin/bash
echo 'Sarting...'

export GITALB_TOKEN=""
export GITLAB_URL=""
groups=$(curl -s --header "Private-Token: ${GITLAB_TOKEN}" $GITLAB_URL/api/v4/groups | jq -c '.[] | {id,full_path}')
groupsArray=("$groups")

rm -f terraform_import_groups.sh
rm -f terraform_import_group_membership.sh

for group in ${groupsArray[@]}
do
    id=$(echo $group | jq -r '(.id)')
    name=$(echo $group | jq -r '(.full_path)')
    echo "terraform import 'module.$(echo $name | sed 's/\//_/g').gitlab_group.group' $id" >> terraform_import_groups.sh
    members=$(curl -s --header "Private-Token: ${GITLAB_TOKEN}" $GITLAB_URL/api/v4/groups/$id/members | jq -c '.[] | {id,username,access_level}' )
    membersArray=($members)
    for member in ${membersArray[@]}
    do
        username=$(echo $member | jq -r '(.username)')
        userId=$(echo $member | jq -r '(.id)')
        access_level=$(echo $member | jq -r '(.access_level)')
        # GitLab group membership can be imported using an id made up of `group_id:user_id`, e.g.
        echo "terraform import gitlab_group_membership.test \"$id:$userId\"" >> terraform_import_group_membership.sh
    done
done

sort -o terraform_import_groups.sh terraform_import_groups.sh
sort -o terraform_import_group_membership.sh terraform_import_group_membership.sh
