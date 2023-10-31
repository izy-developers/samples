import { currentEnvironment } from '@/server/utils/constants.server';
import { isPreview } from '@/utils/constants.universal';
import { adaptiveEventHandler } from '@/server/utils/handlers';
import { GetAllSiteScriptsQuery } from '#gql';

export default adaptiveEventHandler(
  async (event) => {
    const { locale } = getQuery(event) as any;
    const localeGql = locale === process.env.DEFAULT_LOCALE ? 'en' : locale || 'en';
    return await GqlGetAllSiteScripts({
      siteName: process.env.SITE,
      locale: localeGql,
      preview: isPreview,
    }).catch(({ response }) => response?.data as GetAllSiteScriptsQuery);
  },
  {
    name: 'gql:all-site-scripts',
    group: currentEnvironment,
    swr: true,
    maxAge: 60 * 60 * 24 * 7, // 1 week
    getKey: () => 'allsitescripts',
  },
  true,
);
