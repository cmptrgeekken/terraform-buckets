const AWS = require('aws-sdk')

exports.handleNewVideo = async function (event) {
    console.log('handleNewFile lambda running')

    const S3 = new AWS.S3({'signatureVersion': 'v4'})

    for (const rec of event.Records) {
        const bucket = rec.s3.bucket.name
        const key = rec.s3.object.key

        const Metadata = await S3.headObject({
            Key: key,
            Bucket: bucket
        }).promise().catch(err => {
            console.error('failed to read object metadata for ', key)
            throw err
        })

        const fileType = Metadata.ContentType

        console.log(`From bucket: ${bucket}, retrieved object: ${key} w/ file type: ${fileType}`)

        if (['video/quicktime', 'video/mp4'].indexOf(fileType) >= 0) {
            const res = await S3
                .copyObject({
                    Bucket: process.env.CLEAN_BUCKET,
                    CopySource: `${bucket}/${key}`,
                    Key: key
                }).promise()
                .catch(err => {
                    console.error('Failed to put object from dirty bucket', {bucket: process.env.CLEAN_BUCKET, key})
                    throw err
                })

            console.log(`Successfully copied object to ${process.env.CLEAN_BUCKET}: ${JSON.stringify(res)}`)
        } else {
            console.log(`Skipped copying object to ${process.env.CLEAN_BUCKET} as the file type was not allowed!`)
        }
    }
}