import React from "react";
import { useLang } from "../context/Lang";

import './Spectator.scss';

interface Props {
    spectating: boolean;
    spectatorTarget: string;
}

const Spectator: React.FC<Props> = ({ spectating, spectatorTarget }) => {
    const { t } = useLang();
    
    return (
        <>
            {(spectating === true) &&
                <div id="pageSpectator" className="page">
                    <div className={"infoBox notReady"}>
                        <h1>{spectatorTarget??''}</h1>
                        <h3>{t('spectating')}</h3>
                    </div>
                </div>
            }
        </>
    );
};

export default Spectator;
