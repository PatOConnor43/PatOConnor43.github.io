#! /bin/bash
now=`date "+%s"`
one_day_ago=$((now - 86400))

item_json=`cat public/index.xml | hq '{item: item | {title: title, pubDate: pubDate, guid: guid, description: description}}'`
pubDate=`echo $item_json | jq -r '.item.pubDate'`

platform=`uname | tr '[:upper:]' '[:lower:]'`
if [ "$platform" = "darwin" ]; then
    # Mac specific flags
    pubDate_unix=`date -j -f "%a, %d %b %Y %H:%M:%S %z" "$pubDate" "+%s"`
else
    pubDate_unix=`date -d "$pubDate" "+%s"`
fi

diff_unix=$((pubDate_unix - one_day_ago))

if [ $diff_unix -ge 0 ]; then
    domain=$MASTODON_DOMAIN
    token=$MASTODON_ACCESS_TOKEN
    visibility="${MASTODON_VISIBILITY:-public}"


    title=`echo $item_json | jq -r '.item.title' | tr '"' "'"`
    link=`echo $item_json | jq -r '.item.guid'`
    tags=`echo $item_json | jq -r '.item.description' | sed -nr 's/.*::: (.*) :::.*/\1/p'`
    tag_string=""
    if [ "$tags" != "" ]; then
        tag_string=`echo $tags | sed -r 's/(\w+)/\#\1/g'`
    fi

    echo "Posting a toot with the title: $title link: $link tag_string: $tag_string"

    curl -X POST -H "Authorization: Bearer $token" -H "Idempotency-Key: $title" "$MASTODON_DOMAIN/api/v1/statuses" \
        -F "status=$title
$link
$tag_string
" \
        -F "visibility=$visibility" | jq '.'

else
    echo "Most recent title has not been published recently enough. Skipping."
    echo $item_json | jq '.'
fi
