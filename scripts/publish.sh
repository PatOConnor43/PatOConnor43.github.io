#! /bin/bash
now=`date "+%s"`
one_day_ago=$((now - 86400))

item_json=`curl -s 'https://www.xn--z47haa.ws/index.xml' | hq '{item: item | {title: title, pubDate: pubDate, guid: guid}}'`
pubDate=`echo $item_json | jq -r '.item.pubDate'`
pubDate_unix=`date -j -f "%a, %d %b %Y %H:%M:%S %z" "$pubDate" "+%s"`
diff_unix=$((pubDate_unix - one_day_ago))

if [ $diff_unix -ge 0 ]; then
    domain=$MASTODON_DOMAIN
    token=$MASTODON_ACCESS_TOKEN
    visibility="${MASTODON_VISIBILITY:-public}"


    title=`echo $item_json | jq -r '.item.title' | tr '"' "'"`
    link=`echo $item_json | jq -r '.item.guid'`

    echo "Posting a toot with the title: $title and link: $link"

    curl -X POST -H "Authorization: Bearer $token" -H "Idempotency-Key: $title" "$MASTODON_DOMAIN/api/v1/statuses" \
        -F "status=$title

$link
" \
        -F "visibility=$visibility" | jq '.'

else
    echo "Most recent title has not been published recently enough. Skipping."
    echo $item_json | jq '.'
fi
