import contentful from 'contentful';
import { isPreview } from './constants.universal';

type CreateClientType = typeof contentful.createClient;

export async function contentfulClient(
  args: {
    type?: string;
    queryParams?: any;
    specificCfClient?: CreateClientType;
    transform?: boolean;
    fromSiteModel?: boolean;
    isDevMode?: boolean;
    locale?: string | null;
    deep?: number;
    getPlainClient?: boolean;
  },
  debug?: {
    reqName?: string;
    emoji?: string;
  }
) {
  const {
    type,
    locale,
    queryParams,
    specificCfClient,
    isDevMode = undefined,
    transform = true,
    fromSiteModel = true,
    deep = 10,
    getPlainClient = false,
  } = args;

  const _debug = {
    startTimePerformance: 0,
    endTimePerformance: 0,
    emoji: debug?.emoji || '',
  };

  const createClient = specificCfClient || contentful.createClient;

  const devHost = 'preview.contentful.com';
  const prodHost = 'cdn.contentful.com';

  const credentials = {
    accessToken: process.env.CONTENTFUL_PREVIEW_TOKEN,
    host: devHost,
  };

  switch (isDevMode) {
    case true:
      credentials.accessToken = process.env.CONTENTFUL_PREVIEW_TOKEN;
      credentials.host = devHost;
      break;
    case false:
      credentials.accessToken = process.env.CONTENTFUL_DELIVERY_TOKEN;
      credentials.host = prodHost;
      break;
    case undefined:
      credentials.accessToken = isPreview
        ? process.env.CONTENTFUL_PREVIEW_TOKEN
        : process.env.CONTENTFUL_DELIVERY_TOKEN;
      credentials.host = isPreview ? devHost : prodHost;
      break;
  }

  const client = createClient({
    headers: {
      'X-Contentful-RateLimit-Reset': 0,
      'X-Contentful-RateLimit-Second-Limit': 50, // on our plan max 20 🤡
    },
    ...credentials,
    space: process.env.CONTENTFUL_SPACE_ID,
    environment: process.env.CONTENTFUL_ENVIRONMENT,
  });

  if (debug?.reqName) {
    _debug.startTimePerformance = performance.now();
    console.info(debug.emoji + `Start getting ${debug.reqName}`);
  }

  if (getPlainClient) return client;

  const localeCf =
    locale === process.env.DEFAULT_LOCALE ? 'en' : locale || 'en';

  return client
    .getEntries({
      locale: localeCf,
      content_type: fromSiteModel ? 'Site' : type || 'Site',
      ...(fromSiteModel ? { 'fields.name': process.env.SITE } : {}),
      ...queryParams,
      include: deep,
    })
    .then((res: any) => (transform ? res.items.map(mapEntry) : res.items))
    .finally(() => {
      if (debug?.reqName) {
        _debug.endTimePerformance = performance.now();
        console.info(
          debug.emoji +
            debug.reqName +
            ` gotten in ${Math.round(
              _debug.endTimePerformance - _debug.startTimePerformance
            )} ms`
        );
      }
    });
}

export function mapEntry(entry) {
  if (!entry) return;

  const __metadata = {
    id: entry.sys?.id,
    modelName: entry.sys?.contentType?.sys?.id || entry.sys?.type,
    createdAt: entry.sys?.createdAt,
    updatedAt: entry.sys?.updatedAt,
    locale: entry.sys?.locale,
    tags:
      entry.metadata?.tags
        ?.map((tag) => tag.sys?.id)
        .filter(Boolean)
        .filter((tag) => tag.startsWith('topic')) || [],
  };

  if (entry.sys?.type === 'Asset') {
    if (entry.fields?.file?.url) return `https:${entry.fields.file.url}`;
    return;
  }

  if (!entry?.fields) return;

  return {
    ...Object.entries(entry?.fields || {}).reduce((acc, [key, value]) => {
      acc[key] = value && parseField(value);
      return acc;
    }, {}),
    __metadata,
  };
}

export function parseField(value: any) {
  const isArray = Array.isArray(value);
  // Capture contentful Entries
  if (typeof value === 'object' && value.sys) return mapEntry(value);
  // Capture Repeater app
  if (isArray && value[0]?.key) return value;
  // Capture Bynder app (image, video, document)
  if (isArray && ['image', 'document', 'video'].includes(value[0]?.type))
    return value[0];
  // Capture contentful lists
  if (isArray && typeof value[0] === 'string') return value;
  // Capture contentful array of Entries
  if (isArray) return value.map(mapEntry).filter(Boolean);
  // Return plain json
  return value;
}
