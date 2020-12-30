import React, { useContext } from 'react';

export const LangContext = React.createContext({
    t: (key: string) => Object,
});

export function useLang() {
    return useContext(LangContext);
}
