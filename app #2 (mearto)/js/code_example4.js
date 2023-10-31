import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";

export const apiSlice = createApi({
  // The cache reducer expects to be added at `state.api` (already default - this is optional)
  reducerPath: "api",
  baseQuery: fetchBaseQuery({
    baseUrl: "/api/v1",
    prepareHeaders: (headers, { getState }) => {
      const token = document.querySelector('meta[name="csrf-token"]').content;

      headers.set("X-CSRF-Token", token);
      headers.set("Content-Type", "application/json");

      return headers;
    },
  }),
  tagTypes: ["CompanyList", "ProjectList"],
  // The "endpoints" represent operations and requests for this server
  endpoints: (builder) => ({
    getCompanies: builder.query({
      query: () => "/companies/index",
      providesTags: ["CompanyList"],
    }),
    getCompany: builder.query({
      query: (companyId) => `/companies/${companyId}`,
      providesTags: ["CurrentCompany"],
    }),

    getProjects: builder.query({
      query: (companyId) => `/projects/index?company_id=${companyId}`,
      providesTags: ["ProjectList"],
    }),
    getProject: builder.query({
      query: (projectId) => `/projects/${projectId}`,
      providesTags: ["CurrentProject"],
    }),

    createCompany: builder.mutation({
      query: (companyData) => ({
        url: "/companies/create",
        method: "POST",
        body: companyData,
      }),
      invalidatesTags: ["CompanyList"],
    }),
    updateCompany: builder.mutation({
      query: (companyData) => ({
        url: `/companies/${companyData.companyId}`,
        method: "POST",
        body: companyData,
      }),
      invalidatesTags: ["CompanyList", "CurrentCompany"],
    }),
    updateProject: builder.mutation({
      query: (projectData) => ({
        url: `/projects/${projectData.projectId}`,
        method: "POST",
        body: projectData,
      }),
      invalidatesTags: ["ProjectList", "CurrentProject"],
    }),
    createProject: builder.mutation({
      query: (projectData) => ({
        url: "/projects/create",
        method: "POST",
        body: projectData,
      }),
      invalidatesTags: ["ProjectList"],
    }),
    deleteCompany: builder.mutation({
      query: ({ companyId }) => ({
        url: `/companies/${companyId}`,
        method: "DELETE",
      }),
      invalidatesTags: ["CompanyList"],
    }),
    deleteProject: builder.mutation({
      query: ({ projectId }) => ({
        url: `/projects/${projectId}`,
        method: "DELETE",
      }),
      invalidatesTags: ["ProjectList"],
    }),
  }),
});

// Export the auto-generated hook for the `getCompanies` and other query endpoints
export const {
  useGetCompaniesQuery,
  useGetCompanyQuery,
  useGetProjectsQuery,
  useGetProjectQuery,
  useCreateCompanyMutation,
  useUpdateCompanyMutation,
  useDeleteCompanyMutation,
  useCreateProjectMutation,
  useUpdateProjectMutation,
  useDeleteProjectMutation,
} = apiSlice;
