@description('Name of the image gallery')
param galleryName string

@description('Resource group location')
param location string

resource imageGallery 'Microsoft.Compute/galleries@2024-03-03' = {
  name: galleryName
  location: location
  properties: {
    description: 'Shared image gallery created via Bicep module'
  }
}
