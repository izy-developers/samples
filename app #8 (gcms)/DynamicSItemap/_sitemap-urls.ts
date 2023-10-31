import { currentEnvironment } from '@/server/utils/constants.server';
import { contentfulClient } from '@/utils/cms-contentful';
import { localizePaths } from '@/utils/universal-utils';

export default cachedEventHandler(
  async () => {
    const rawSlugs = await Promise.all(
      process.env.LOCALES.split(', ').map(async (locale) => {
        return await contentfulClient({
          type: 'PageLayout',
          locale: locale,
        }).then((items) =>
          items.length > 0
            ? {
                locale,
                slugs: (items[0].pages || [])
                  .map((page) => (page.index ? page.slug : null))
                  .filter(Boolean),
              }
            : null,
        );
      }),
    );

    return localizePaths(rawSlugs).map((page) => {
      return { loc: page, lastmod: new Date() };
    });
  },
  {
    name: 'rest:sitemap-dynamic-urls',
    group: currentEnvironment,
    maxAge: 60 * 10, // 10 minutes
  },
);
